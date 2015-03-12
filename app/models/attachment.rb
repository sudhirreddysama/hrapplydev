class Attachment < ActiveRecord::Base

	belongs_to :applicant
	
	def convert_file file
		self.name = file.original_filename
		if File.extname(name).downcase == '.txt'
			return false
		end
		File.open(path, 'w') { |f| f.write file.read }
		`/usr/local/bin/convert #{path} #{pdf_path}`
		if File.exists? pdf_path
			return true
		else
			File.delete path
			return false
		end
	end
	
	def pdf_editable
		`pdftk #{pdf_path} output #{pdf_test_path}`
		if File.exists? pdf_test_path
			return true
			`rm #{pdf_test_path}`
		else
			return false
		end
	end
	
	def path
		"attachments/#{id}#{File.extname(name)}"
	end
	
	def pdf_path
		"attachments/#{id}.pdf"
	end
	
	def pdf_test_path
		"attachments/#{id}-test.pdf"
	end

	def trash_file
		File.delete path if File.exists? path
		File.delete pdf_path if File.exists? pdf_path
		true
	end
	before_destroy :trash_file
	
	def clone
		a = super
		a.save
		`cp #{path} #{a.path}`
		`cp #{pdf_path} #{a.pdf_path}`
		return a
	end
	
end