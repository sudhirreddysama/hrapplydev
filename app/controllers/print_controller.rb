class PrintController < ApplicationController
	
	before_filter :rl; def rl; require_level 10; end
	
	def index
		render :nothing => true
		return
	
		@objs = Print.paginate :order => 'prints.to desc', :page => params[:page], :per_page => 100
		@exam_types = ExamType.find(:all, :order => :sort)
		@objs2 = {}
		froms = {}
		to = Time.now
		@exam_types.each { |et|
			from = Print.maximum(:to, :conditions => ['exam_type_id = ? or exam_type_id is null', et.id])
			froms[et.id] = from
			@objs2[et.id] = Applicant.find(
				:all, {
					:conditions => ['applicants.submitted_at > ? and applicants.submitted_at <= ? and exams.exam_type_id = ?', from ? from : '0', to, et.id], 
					:include => [{:exam_prices => :exam}],#, :user, :trainings, :certifications, :other_exams, :educations, :employments, :attachments],
					:order => 'applicants.last_name, applicants.first_name'
				}
			)
		}
		
		if request.post?
			p = Print.new :from => froms[params[:exam_type_id].to_i], :to => to, :exam_type_id => params[:exam_type_id]
			if p.exam_type_id
				p.applicant_count = @objs2[p.exam_type_id].length
				if p.applicant_count > 0
					batch p
					redirect_to
				end
			end
		end
	end
	
	def download
		@obj = Print.find params[:id]
		send_file @obj.filepath, :filename => "batch.pdf", :disposition => 'inline', :type => 'application/pdf'
	end
	
	
	def rebuild
		p = Print.find params[:id]
		@objs2 = {}
		@objs2[p.exam_type_id] = Applicant.find(
			:all, { 
				:conditions => [(p.exam_type_id ? 'exams.exam_type_id = %d and ' % p.exam_type_id : '') + 'applicants.submitted_at > ? and applicants.submitted_at <= ?', p.from ? p.from : '0', p.to], 
				:include => [{:exam_prices => :exam}, :user, :trainings, :certifications, :other_exams, :educations, :employments, :attachments],
				:order => 'applicants.last_name, applicants.first_name'
			}
		)
		batch p
		redirect_to :action => :index
	end
	
	private
	
	# Helps with the printing process. Mimics an applicant with one exam_price. This way we can sort the
	# applicants by exam name and have the application show up multiple times on the list if they applied
	# for more than one exam at the same time.
	class ApplicantOneExam
		
		attr :applicant, true
		attr :exam_prices, true
		
		def method_missing meth, *args
			@applicant.send meth, *args
		end
	
	end
	
	
	def batch p
			
		# Try to make a temporary directory for our stuff. If the directory already exists then bail because
		# another print job is already running.
		
		tmpdir = "tmp/print-tmp"
		return false if File.exists? tmpdir
		`mkdir #{tmpdir}`
		
		# Create a print record and find applicants to print.
		
		@objs = @objs2[p.exam_type_id]
		
		
		# Reorder objs by exam name, last name, first name. 
		
		@objs_indexed = {}
		@exams = []
		@objs.each { |o|
			o.exam_prices.each { |ep|
				if !@objs_indexed[ep.exam_id]
					@objs_indexed[ep.exam_id] = []
					@exams << ep.exam
				end
				aoe = ApplicantOneExam.new
				aoe.exam_prices = [ep]
				aoe.applicant = o
				o.print_exam_prices = [ep]
				@objs_indexed[ep.exam_id] << aoe
			}
		}
		
		@exams.sort! { |a, b| a.name <=> b.name }		
		
		p.save
		
		# Loop through all the applicants to generate the first phase of the batch print.
		
		files = ''
		path = `pwd`.strip + '/public/images'	
		
		if p.exam_type && p.exam_type.print_summary
		
			# Overview page
			f = "#{tmpdir}/overview.pdf"
			IO.popen('htmldoc -f ' + f + ' -t pdf --path "' + path + '" --webpage --header "..." --footer "..." --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 8 --headfootfont Arial --headfootsize 8 -', 'w+') { |io|
				html = render_to_string(:template => 'print/overview.rhtml', :layout => false)
				File.open("#{tmpdir}/overview.html", 'w') { |html_file| html_file.write(html) }
				io.puts html
				io.close_write
			}
			files = f + ' '
		
		end
		
		@obj_batch_index = -1;
		
		@first_page = false
		
		@exams.each { |e|
			@objs_indexed[e.id].each { |@obj| 
				@obj_batch_index += 1
		
				# Generate the 'general' pages.
				
				@pdf_mode = 'general'
				f = "#{tmpdir}/#{@obj.id}.pdf"
				@first_page = false
				IO.popen('htmldoc -f ' + f + ' -t pdf --path "' + path + '" --webpage --header "..." --footer "..." --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 8 --headfootfont Arial --headfootsize 8 -', 'w+') { |io|
					html = render_to_string(:template => 'applicants/pdf.rhtml', :layout => false)
					File.open("#{tmpdir}/#{@obj.id}.html", 'w') { |html_file| html_file.write(html) }
					io.puts html
					io.close_write
				}
				files += f + ' '
				
				# Add the attachments to the file list.
				@obj.attachments.each { |a| files += a.pdf_path + ' ' }
				
			}
		}
			
			# Loop through the applicants again (per section) and gather the HTML for the "other" pages. These will be sent to 
			# HTMLDOC in bulk since it would be slow to glue them together with ghostscript individually.
			
		@first_page = false
		other_html = ''
		%w{other_exams veteran typing equal supplement}.each { |@pdf_mode|
			@obj_batch_index = -1;
		
			@exams.each { |e|
				@objs_indexed[e.id].each { |@obj| 
					@obj_batch_index += 1
				
					do_print = true
					do_print = false if @pdf_mode == 'other_exams' and @obj.other_exams.empty?
					do_print = false if @pdf_mode == 'supplement' and (!@obj.ask_loans or (!@obj.loans_outstanding and !@obj.loans_default))
					do_print = false if @pdf_mode == 'veteran' and (@obj.vc_type.nil? or @obj.vc_type == 'none')
					do_print = false if @pdf_mode == 'typing' and !@obj.typing_waiver
					if do_print
						other_html += render_to_string(:template => 'applicants/pdf.rhtml', :layout => false)
					end
					@first_page = true
				}
			}
		}
		
		# Sent the gathered HTML for the 'other' pages to HTMLDOC
		
		f = "#{tmpdir}/other.pdf"
		IO.popen('htmldoc -f ' + f + ' -t pdf --path "' + path + '" --webpage --header "..." --footer "..." --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 8 --headfootfont Arial --headfootsize 8 -', 'w+') { |io|
			io.puts other_html
			io.close_write
		}
		files += f + ' '
		
		# Send the file list string to ghostscript so it can glue them altogether. This is the slowest
		# part of the process - way to speed up?
		
		`pdftk #{files} cat output #{p.filepath}`
		logger.info "pdftk #{files} cat output #{p.filepath}"
		logger.info '?????'
		

		# Remove the temporary directory so other print jobs can now run.
		
		`rm -rf #{tmpdir}`
		
		# DONE
		
		return true
		
	end
	
end
