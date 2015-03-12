class ExportController < ApplicationController
	
	before_filter :authenticate
	
	def authenticate
		authenticate_or_request_with_http_basic { |user_name, password|
			user_name == 'pstek' && password == 'tek.ps.export.!?'
		}
	end
	
	def index
	
		cond = 'exam_types.include_in_export = 1'
		if params[:testmode]
			cond += ' and applicants.submit_complete = 1'
		else
			cond += ' and applicants.submit_complete = 1 and applicants.submitted_at < ? and applicants.exported = 0'
		end
	
		upto = Print.maximum(:to)
		eps = ExamPrice.find(:all, 
			:include => [{:applicant => :user}, {:exam => :exam_type}], 
			:conditions => params[:testmode] ? cond : [cond, upto],
			:limit => params[:testmode] ? '500' : nil,
			:order => 'applicants.submitted_at desc')
		csv = FasterCSV.generate(:force_quotes => true) { |csv| 
			csv << [
				'Exam Title',
				'Exam Number',
				'Exam Date',
				'Application Datetime',
				'Last Name',
				'First Name',
				'Street Address',
				'Street Address 2',
				'City',
				'State',
				'Zip',
				'Legal Address',
				'Phone',
				'Work Phone',
				'Cell Phone',
				'SSN',
				'DOB',
				'School District',
				'County',
				'Village',
				'Town',
				'Email Address',
				'Gender',
				'Race',
				'Ethnicity',
				'Veteran',
				'Fire',
				'PaidCC',
				'PayType'
			]
			eps.each { |ep|
				e = ep.exam
				a = ep.applicant
				u = a.user
				csv << [
					e.name, 
					e.no, 
					e.exam_date ? e.exam_date_before_type_cast : '',
					a.submitted_at ? a.submitted_at_before_type_cast : '',
					a.last_name, 
					a.first_name, 
					a.address, 
					a.address2, 
					a.city, 
					a.state, 
					a.zip, 
					a.residence_different ? "#{a.res_address} #{a.res_city} #{a.res_state} #{a.res_zip}" : "#{a.address} #{a.address2} #{a.city} #{a.state} #{a.zip}", 
					a.home_phone, 
					a.work_phone, 
					'', 
					a.ssn, 
					a.dob, 
					a.school, 
					a.residence_different ? a.res_county : a.county, 
					a.village, 
					a.town, 
					u.email, 
					a.gender, 
					a.race == 'hispanic' ? 'T' : 'F', 
					{'americanindian' => '10000', 'asian' => '01000', 'black' => '00100', 'pacific' => '00010', 'white' => '00001'}[a.race] || '00000', 
					{'none' => 1, 'nondisabled' => 2, 'disabled' => 3}[a.vc_type] || 1,
					a.fire,
					a.waiver_requested ? 'F' : 'T',
					a.total.to_f == 0 ? 'nofee' : !a.waiver_requested ? 'paid-cc' : (a.waiver_county || a.waiver_social_workers) ? 'waiver-employee' : 'waiver-normal'
				]
			}
		}
		unless params[:testmode]
			eps.each { |ep|
				ep.applicant.update_attribute :exported, 1
			}
		end
		save_to_basename = Time.now.strftime 'exports/%Y-%m-%d-%H-%M-%S-'
		i = 0
		save_to = ''
		begin
			save_to = "#{save_to_basename}#{i}"
			i += 1
		end while File.exists? save_to
		File.open(save_to, 'w') { |f| f.write csv }
		send_data csv, :type => 'text/csv', :filename => 'export.csv'
	end

end