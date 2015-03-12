class Notifier < ActionMailer::Base
  
  HR_FROM = 'Monroe County <noreply@monroecounty.gov>'
  
	def lost_password u, url
		recipients u.email_with_name
		from HR_FROM
		subject 'Account Recovery'
		body :u => u, :url => url
	end
	
	def registered u, url
		recipients u.email_with_name
		from HR_FROM
		subject 'Account Activation'
		body :u => u, :url => url
	end
	
	def application_created a, url
		recipients a.user.email_with_name
		from HR_FROM
		subject 'Application Created'
		body :a => a, :url => url
	end
	
	def application_submitted a, url
		recipients a.user.email_with_name
		from HR_FROM
		subject 'Application Submitted'
		body :a => a, :url => url
	end
	
	def application_approved a, exam_prices, url
		recipients a.user.email_with_name
		from HR_FROM
		subject 'Exam Application Submitted'
		body :a => a, :url => url, :exam_prices => exam_prices
	end
	
	def application_rejected a, exam_prices, url
		recipients a.user.email_with_name
		from HR_FROM
		subject 'Exam Application Submitted'
		body :a => a, :url => url, :exam_prices => exam_prices
	end
	
	def message m
		recipients m.to_email
		from m.from_email
		subject m.subject
		body m.body
	end
	
	def subscription s, exams
		recipients s.email
		from HR_FROM
		subject 'New Civil Service Postings'
		body :s => s, :exams => exams
	end

	def mailtest
		recipients ['jesse@unicornelex.com', 'jessesternberg@monroecounty.gov']
		subject 'Test Email From HRAPPLY'
		from HR_FROM
		body :a => 'TEST'
	end

	#def recipients *args
		#if RAILS_ENV == 'development'
	#		super ['jesse@unicornelex.com', 'jessesternberg@monroecounty.gov']
		#else
		#	super *args
		#end
	#end

end
