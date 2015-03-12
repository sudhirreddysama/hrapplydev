class ApplicantsController < ApplicationController
	
	before_filter :check_login, :except => :maxpdf
	
	filter_parameter_logging :new_payment
	
	def check_login
		if !@current_user
			session[:after_login] = url_for(:controller => :applicants, :action => :index)
			redirect_to :controller => :account, :action => :index
			return false
		end
		return true
	end
	
	def index
		@objs = @current_user.applicants
	end
	
	def load_obj
		if @current_user.level == 0
			@obj = @current_user.applicants.find params[:id]
		else 
			@obj = Applicant.find params[:id]
		end
		@noform = @obj.submit_complete
	end
	before_filter :load_obj, :except => [:index, :address_ac]
	
	def attachment
		a = @obj.attachments.find params[:id2]
		
		send_file File.exists?(a.path) ? a.path : a.pdf_path, :filename => a.name
	end
	
	def general	
		@obj.section = params[:action]
		if !@noform and request.post? and @obj.update_attributes params[:obj] and !@obj.dont_redirect
			redirect_to :action => ((params[:goto_attachments] and @obj.section == 'view') ? 'attachments' : @obj.section), :id => @obj.id, :anchor => @obj.section_anchor
			
			if params[:action] == 'general'
				if !@obj.residence_different
					@obj.res_address = ''
					@obj.res_city = ''
					@obj.res_state = ''
					@obj.res_zip = ''
					@obj.res_county = ''
					@obj.save
				end
			end
			
		end
	end
	
	alias_method :exams, :general
	alias_method :certifications, :general
	alias_method :education, :general
	alias_method :training, :general
	alias_method :employment, :general
	alias_method :veteran, :general
	alias_method :equal, :general
	alias_method :typing, :general
	alias_method :waiver, :general
	alias_method :attachments, :general
	alias_method :comments, :general
	alias_method :supplement, :general
	alias_method :other_exams, :general
		
	def submit
	
		# Quick hack to clear errors for sections no longer required after an exam is removed because the deadline passed.
		['typing', 'waiver', 'other_exams', 'supplement'].each { |s|
			@obj.section = s
			@obj.validate_section
			@obj.dont_validate = false
		}
	
		@obj.section = params[:action]
		if !@noform and request.post? and @obj.update_attributes params[:obj] and !@obj.dont_redirect
			redirect_to :action => @obj.section, :id => @obj.id, :anchor => @obj.section_anchor
			if @obj.submit_complete
				Notifier.deliver_application_submitted @obj, url_for(:controller => :applicants, :action => :index, :id => nil)
			end
		end
	end
	
	
	
	
	def pdf
	
		files = ''
	
		tmpdir = "tmp/print-tmp-#{@obj.id}"
		if File.exists? tmpdir
			count = 0
			while File.exists? "#{tmpdir}-#{count}"
				count += 1
			end
			tmpdir = "#{tmpdir}-#{count}"
		end
		`mkdir #{tmpdir}`
		
		path = `pwd`.strip + '/public/images'
		f = "#{tmpdir}/#{@obj.id}.pdf"
		IO.popen('HTMLDOC_NOCGI=TRUE;export HTMLDOC_NOCGI;htmldoc -f ' + f + ' -t pdf --path "' + path + '" --webpage --header "..." --footer "..." --top .25in --bottom .25in --left .25in --right .25in --textfont Arial --fontsize 8 --headfootfont Arial --headfootsize 8 -', 'w+') { |io|
			html = render_to_string(:template => 'applicants/pdf.rhtml', :layout => false)
			io.puts html
			io.close_write
		}

		
		files += f + ' '

		# Add the attachments to the file list.
		@obj.attachments.each { |a| files += a.pdf_path + ' ' }
		
		outfile = "prints-individual/#{@obj.id}.pdf"
		`pdftk #{files} cat output #{outfile}`
		`rm -rf #{tmpdir}`
		send_file outfile, :filename => 'application.pdf'

	end

	#def maxpdf
	#	r = DB.query('select * from applicants a join mccs.applicants a2 on a2.web_applicant_id = a.id where a2.id = %d and a.id = %d', params[:id2], params[:id])
	#	if r.fetch_hash
	#		pdf
	#	else
	#		render :nothing => true
	#	end
	#end



	def address_ac
		adr = params[:adr].gsub(/[^a-zA-Z0-9 ]/, '').strip
		words = adr.split(' ')
		@no = words.shift
		q = nil
		words.each { |w|
			w.strip!
			unless w.blank?
				q = (q ? "#{q} " : '') + "+#{w}*"
			end
		}
		if q
			@result = DB.query('
				select p.*, match(p.search) against ("%s" in boolean mode) score
				from mccs.rps_parcels p
				where match(p.search) against ("%s" in boolean mode) > 0
				and %d between no_min and no_max
				order by score desc limit 20
			', q, q, @no.to_i)
			render :layout => false
		else
			render :text => ''
		end
	end


















end