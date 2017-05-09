class Applicant < ActiveRecord::Base

  belongs_to :user
  has_many :payments, :dependent => :destroy
  has_many :exam_prices, :order => 'exam_prices.sort', :dependent => :destroy
  has_many :exams, :through => :exam_prices
  has_many :educations, :order => 'educations.sort', :dependent => :destroy
  has_many :certifications, :order => 'certifications.sort', :dependent => :destroy
  has_many :trainings, :order => 'trainings.sort', :dependent => :destroy
  has_many :employments, :order => 'employments.sort', :dependent => :destroy
  has_many :other_exams, :order => 'other_exams.sort', :dependent => :destroy
  has_many :attachments, :order => 'attachments.sort', :dependent => :destroy
  has_many :saved_errors, :order => 'saved_errors.sort', :dependent => :destroy
	has_one :cs_applicant, :foreign_key => 'web_applicant_id'
	
  def name
    "#{first_name} #{last_name}"
  end

  def label
    "Application ##{id}"
  end

  def exam_nos;
    exams.collect &:no;
  end

  EDUCATION_LEVELS =
      [['Less than high school graduation', 'lths'],
       ['G.E.D. (general equivalency diploma)', 'ged'],
       ['High school diploma', 'hsd'],
       ['2-year college (no degree)', '2yc'],
       ['Associate\'s degree', 'assoc'],
       ['4-year college (no degree)', '4yc'],
       ['Bachelor\'s degree', 'bach'],
       ['Graduate study beyond Bachelor\'s', 'bgrad'],
       ['Master\'s degree', 'master'],
       ['Graduate study beyond Master\'s', 'mgrad'],
       ['Doctorate', 'doc']]

  PAY_METHODS =
      [['Credit', 'credit'],
       ['Check', 'check'],
       ['Money Order', 'moneyorder']]

  PAY_CARD_TYPES =
      [['VISA', 'visa'],
       ['MasterCard', 'mc'],
       ['American Express', 'amex'],
       ['Discover', 'disc']]

  STATUSES = ['unfinished', 'submitted', 'rejected', 'approved', 'expired']

  attr :add_exam_no, true
  attr :new_educations
  attr :new_certifications
  attr :new_trainings
  attr :new_employments
  attr :new_other_exams
  attr :new_attachments
  attr :form_target
  attr :do_validation
  attr :submit, true
  attr :save_continue, true
  attr :save_exit, true
  attr :submit_success
  attr :save_validate, true
  attr :save_view, true

  def residence_same
    return !residence_different
  end

  def residence_same= v
    self.residence_different = (v == '0')
  end

  def calc_total
    self.total = exam_prices.sum('price').to_f
    self.payment_fee = (total > 0) ? System.find(1).payment_fee : 0
    self.total += payment_fee
    SavedError.delete_all ['applicant_id = ? and section = "exams" and field = "exams"', id]
    SavedError.create :applicant => self, :field => 'exams', :section => 'exams', :message => 'You cannot submit an application with no exams / jobs' if exam_prices(true).empty?
  end

  def self.setup_and_create u, ids, pay_fee
    last = u.applicants.find :first, :order => 'applicants.created_at desc'
    if last
      if last.submit_complete
        a = last.clone
        a.applied_before = true
        a.previous_first_name = a.first_name
        a.previous_last_name = a.last_name
        
        p = last && last.cs_applicant && last.cs_applicant.cs_person
        if p
        	if / [A-Z]\.$/.match(p.first_name)
        		a.first_name = p.first_name[0..-4]
        		if a.middle_name.blank?
        			a.middle_name = p.first_name[-2,2]
        		end
        	else
        		a.first_name = p.first_name
        	end
        	a.middle_name = p.middle_name if !p.middle_name.blank?
        	a.last_name = p.last_name
        	a.home_phone = p.home_phone
        	a.work_phone = p.work_phone
        	a.user.email = p.email
        	a.address = p.mailing_address
        	a.address2 = p.mailing_address2
        	a.city = p.mailing_city
        	a.state = p.mailing_state
        	a.zip = p.mailing_zip
        	a.county = p.mailing_county
        	a.residence_different = p.residence_different
        	a.res_address = p.residence_address
        	a.res_city = p.residence_city
        	a.res_state = p.residence_state
        	a.res_zip = p.residence_zip
        	a.res_county = p.residence_county
					a.dob = p.date_of_birth
					a.gender = p.gender
					a.contact_via = p.contact_via
        end
        a.save
        a.user.save
        msg = 'Application has been created. For convenience, the application has been populated with the information you entered in your last application.'
      else
        a = last
        msg = 'You already have an unfinished application open. The exams / jobs you have selected have been added to this application.'
      end
    else
      a = Applicant.create :first_name => u.first_name, :last_name => u.last_name, :user => u
      a.educations << Education.new
      a.employments << Employment.new
      msg = 'Application has been created.'
    end
    a.save
    Exam.find(:all, :conditions => ['id in (?)', ids]).each_with_index { |e, i|
      a.exam_prices.create(:exam => e, :price => e.price.to_f, :status => 'unfinished', :sort => i) unless a.exam_ids.include? e.id
    }
    a.exams_complete = true
    a.payment_fee = pay_fee
    a.calc_total
    a.save
    return a, msg
  end

  def clone
    a = super
    a.exported = false
    a.exported_mccs = false
    a.submitted_at = nil
    a.waiver_denied = false
    a.waiver_paid = false
    a.validated = false
    a.created_at = Time.now
    a.confirmed = false
    a.general_complete = false
    a.certifications_complete = false
    a.education_complete = false
    a.training_complete = false
    a.employment_complete = false
    a.veteran_complete = false
    a.equal_complete = false
    a.attachments_complete = false
    a.comments_complete = false
    a.supplement_complete = false
    a.typing_complete = false
    a.waiver_complete = false
    a.other_exams_complete = false
    a.submit_complete = false
    a.exams_expired = false
    a.town = ''
    a.village = ''
    a.school = ''
    a.fire = ''
    a.save
    educations.each { |e| n = e.clone; n.admin_notes = ''; n.applicant_id = a.id; n.save }
    certifications.each { |c| n = c.clone; n.admin_notes = ''; n.applicant_id = a.id; n.save }
    trainings.each { |t| n = t.clone; n.admin_notes = ''; n.applicant_id = a.id; n.save }
    employments.each { |em| n = em.clone; n.admin_notes = ''; n.applicant_id = a.id; n.save }
    attachments.each { |at| n = at.clone; n.applicant_id = a.id; n.save }
    a
  end

  # This is a hack for printing batches. The "ask_loans", etc. flags need to look at only the exam_price
  # currently being printed, so the print_exam_prices allows it to be overridden.
  attr :print_exam_prices, true

  def print_exam_prices
    @print_exam_prices || exam_prices
  end

  def ask_loans
    print_exam_prices.to_a.find { |e| e.exam.ask_loans }
  end

  def minimum_age
    print_exam_prices.collect { |e| e.exam.minimum_age }.reject(&:blank?).max
  end
  
  def require_graduation_date
		print_exam_prices.to_a.find { |ep| ep.exam.require_degree }  
  end

  def ask_typing_waiver
    print_exam_prices.to_a.find { |e| e.exam.ask_typing_waiver }
  end

  def license_requirement
    print_exam_prices.collect { |e| e.exam.license_requirement }.reject(&:blank?).join(', ')
  end

  def ask_veterans
    print_exam_prices.to_a.find { |e| e.exam.ask_veterans }
  end

  def ask_fee_waiver
    print_exam_prices.to_a.find { |e| e.exam.ask_fee_waiver }
  end

  def ask_crossfiler
    print_exam_prices.to_a.find { |e| e.exam.ask_crossfiler }
  end

  def self.check_expired
    ExamPrice.find(:all, :include => [:exam, :applicant], :conditions => 'date_add(exams.deadline, interval 5 minute) < now() and applicants.submit_complete = 0').each { |ep|
      ep.destroy
      ep.applicant.calc_total
      ep.applicant.update_attribute :exams_expired, true
    }
  end

  def has_applied_before
  	# Disabling code by returning early.
  	return false, ''
  	#
    exam_prices.each { |ep|
      result=DB.query("select applicants.id as id, applicants.submitted_at as sa from applicants inner join exam_prices on applicants.id = exam_prices.applicant_id
where applicants.id<> #{id} and user_id=#{user_id} and exam_id=#{ep.exam_id} and applicants.submitted_at is not null")
      result.each_hash { |o|
        if (o.id > "0")
          return true,"You have a previous application for the #{ep.exam.name} that you submitted on #{o.sa.to_time.strftime('%m/%d/%Y')}. If you would like to supply missing information on the previous application, please submit the information via email to Civil Service. You can email Civil Service <a style='color: white;text-decoration:underline;' href='mailto:civilservice@monroecounty.gov'>here</a>."
        end
      }
    }
    return false, ''

  end

  def has_payment_fee
    total > 0 and payment_fee > 0
  end

  def reject_waiver
    update_attribute :waiver_denied, true
    exam_prices.each { |ep|
      ep.update_attribute :status, 'must-pay' if ep.status == 'submitted'
    }
  end

  def apply_template txt, ep, url = ''
    txt.gsub('<<first_name>>', first_name).
        gsub('<<last_name>>', last_name).
        gsub('<<id>>', id.to_s).
        gsub('<<jobs>>', exam_prices.collect { |ep| "#{ep.exam.no}, #{ep.exam.name}" }.join('\r')).
        gsub('<<total>>', sprintf('%.2d', total)).
        gsub('<<url>>', url).
        gsub('<<job>>', ep ? "#{ep.exam.no}, #{ep.exam.name}" : '')
  end


  attr :section, true
  attr_reader :section_anchor

  attr :new_exam_price_no, true
  attr_writer :new_exam_price_no_check
  attr_reader :new_exam_price_no_error

  def new_exam_prices= objs
    objs.each { |sub_id, atr|
      o = exam_prices.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
      else
        o.update_attributes(atr)
      end
    }
    calc_total
  end

  def new_exam_price_no_save
    return unless @new_exam_price_no_check
    e = Exam.find_by_no @new_exam_price_no
    if e
      if exam_prices.to_a.find { |ep| ep.exam == e }
        @new_exam_price_no_error = 'Exam / Job has already been added'
        return false
      end
      o = ExamPrice.create :applicant => self, :sort => exam_prices.maximum(:sort).to_i + 1, :exam => e, :price => e.price
      calc_total
    else
      @new_exam_price_no_error = 'Exam / Job not found'
      return false
    end
    @dont_validate = true
  end

  before_save :new_exam_price_no_save

  def fix_ssn_format
    unless ssn.blank?
      if ssn =~ /\A\d\d\d-?\d\d-?\d\d\d\d\Z/
        fix = ssn.gsub('-', '')
        self.ssn = fix[0..2].to_s + '-' + fix[3..4].to_s + '-' + fix[5..8].to_s
      end
    end
  end

  before_save :fix_ssn_format

  def new_certifications= objs
    objs.each { |sub_id, atr|
      o = certifications.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
      else
        o.update_attributes(atr)
      end
    }
  end

  def new_certification= v
    o = Certification.create :applicant => self, :sort => certifications.maximum(:sort).to_i + 1
    @section_anchor = o.id
    @dont_validate = true
  end

  def new_educations= objs
    objs.each { |sub_id, atr|
      o = educations.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
      else
        o.update_attributes(atr)
      end
    }
  end

  def new_education= v
    o = Education.create :applicant => self, :sort => educations.maximum(:sort).to_i + 1
    @section_anchor = o.id
    @dont_validate = true
  end

  def new_trainings= objs
    objs.each { |sub_id, atr|
      o = trainings.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
      else
        o.update_attributes(atr)
      end
    }
  end

  def new_training= v
    o = Training.create :applicant => self, :sort => trainings.maximum(:sort).to_i + 1
    @section_anchor = o.id
    @dont_validate = true
  end

  def new_employments= objs
    objs.each { |sub_id, atr|
      o = employments.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
      else
        o.update_attributes(atr)
      end
    }
  end

  def new_employment= v
    o = Employment.create :applicant => self, :sort => employments.maximum(:sort).to_i + 1
    @section_anchor = o.id
    @dont_validate = true
  end

  def new_other_exams= objs
    objs.each { |sub_id, atr|
      o = other_exams.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
        SavedError.delete_all ['section = ? and applicant_id = ?', section, id]
      else
        o.update_attributes(atr)
      end
    }
  end

  def new_other_exam= v
    o = OtherExam.create :applicant => self, :sort => other_exams.maximum(:sort).to_i + 1
    @section_anchor = o.id
    @dont_validate = true
  end

  def new_attachments= objs
    objs.each { |sub_id, atr|
      o = attachments.find(sub_id)
      if atr[:remove]
        o.destroy
        @dont_validate = true
        @section_anchor = 'top'
        SavedError.delete_all ['section = ? and applicant_id = ? and sub_id = ?', section, id, o.id]
      else
        o.update_attributes(atr)
      end
    }
  end

  attr_writer :new_attachment
  attr_writer :new_attachment_check
  attr_reader :new_attachment_error

  def new_attachment_save
    return unless @new_attachment_check
    if @new_attachment.blank?
      @new_attachment_error = 'You must select a file to upload'
      return false
    else
      ext = File.extname(@new_attachment.original_filename).downcase
      if @new_attachment.length > 3145728
        @new_attachment_error = 'File is too large'
        return false
      else

        o = Attachment.create :applicant => self, :sort => attachments.maximum(:sort).to_i + 1

        unless o.convert_file @new_attachment

          @new_attachment_error = 'Unacceptable file format - could not convert to PDF'
          o.destroy
          return false

        end

        unless o.pdf_editable

          @new_attachment_error = 'Unacceptable PDF. Maybe it is password protected?'
          o.destroy
          return false

        end

        ActiveRecord::Base.verify_active_connections! # It's possible the conversion could take a while.
        o.save
        @section_anchor = o.id
      end
    end
    @dont_validate = true
  end

  before_save :new_attachment_save

  attr :dont_validate, true

  def age
    dte = exam_prices.to_a.collect { |ep| ep.exam.minimum_age.blank? ? nil : ep.exam.exam_date }.reject(&:blank?).min
    if dte && dob
      dte = dte.to_date
      return dte.year - dob.year - ((dte.month > dob.month || (dte.month == dob.month && dte.day >= dob.day)) ? 0 : 1)
    end
    return nil
  end

  def is_numeric
    true if Float(self) rescue false
  end

  def validate_section
    return if @dont_validate
    @dont_validate = true
    SavedError.delete_all ['section = ? and applicant_id = ?', section, id] unless section == 'exams'
    case section
      when 'exams'
        update_attribute :exams_complete, !@err
      when 'general'
        err 'first_name', 'First name is required' if first_name.blank?
        err 'last_name', 'Last name is required' if last_name.blank?

        err 'first_name', 'Invalid first name' if first_name.include?('@')
        err 'last_name', 'Invalid last name' if last_name.include?('@')

        err 'address', 'Mailing address is required' if address.blank?
        err 'city', 'Mailing address city, state & zip are required' if city.blank? or state.blank? or zip.blank?
        err 'county', 'Mailing address county is required' if county.blank?
        if residence_different
          err 'res_address', 'Residence address is required' if res_address.blank?
          err 'res_city', 'Residence address city, state & zip are required' if res_city.blank? or res_state.blank? or res_zip.blank?
          err 'res_county', 'Residence address county is required' if res_county.blank?
        end
        err 'home_phone', 'Home phone number is required' if home_phone.blank?
        err 'home_phone', 'Home phone number is incorrectly formatted' if !home_phone.blank? and !(home_phone =~ /\A\(?\d\d\d\)?\.?-?\d\d\d\.?-?\d\d\d\d.*\Z/)
        err 'work_phone', 'Work/Alternate phone number is incorrectly formatted' if !work_phone.blank? and !(work_phone =~ /\A\(?\d\d\d\)?\.?-?\d\d\d\.?-?\d\d\d\d.*\Z/)
        if !minimum_age.blank?
          if dob.blank?
            err 'dob', 'Date of birth is required for this application'
          else
            exam_age = age
            if exam_age && exam_age < minimum_age
              err 'dob', "You must be #{minimum_age} years old on the examination date to submit this application"
            end
          end
        end
        if nonseasonal_fields?
        	err 'army_served', 'Please indicate if you have served in the armed forces.' if army_served.nil?
          err 'county_resident_4_mo', 'Please indicate if you have been a county resident for 4 months.' if county_resident_4_mo.nil?
          err 'us_citizen', 'Please indicate if you are a US citizen' if us_citizen.nil?
          err 'us_right_to_work', 'Please indicate if you have the right to work in the united states' if us_citizen == false and us_right_to_work.nil?
          err 'us_right_to_work', 'Please indicate the class of your right to work in the US' if us_citizen == false and us_right_to_work == true and us_right_to_work_class.blank?
          err 'accept_part_time_work', 'Please indicate if you will accept part time work' if accept_part_time_work.nil?
          err 'accept_temp_work', 'Please indicate if you will accept temporary work' if accept_temp_work.nil?
        	err 'army_served', 'Please indicate if you have served in the armed forces' if army_served.nil?
        	if army_served
        		err 'army_from', 'Date of active service start (from) date is required' if army_from.nil?
        		err 'vc_used', 'Please indicate if you have previously been appointed from a civil service list where you were granted veterans credits' if vc_used.nil?
        		if vc_used
        			err 'vc_used_agency', 'Agency that established the eligible list is required' if vc_used_agency.blank?
        		end
        	end
        end
        if seasonal_fields?
          err 'over_18', 'Please indicate if you are over 18 years old' if over_18.nil?
          err 'begin_work', 'Please indicate when you can begin summer work' if begin_work.blank?
          err 'end_work', 'Please indicate when you need to end summer work' if end_work.blank?
          err 'work_weekends', 'Please indicate if you can/cannot work weekends' if work_weekends.nil?
          err 'drivers_license_class', 'Please enter the class of your drivers license' if state_drivers_license && drivers_license_class.blank?
          err 'has_transportation', 'Please indicate if you have transportation to any Monroe County work site' if has_transportation.nil?
        end
        err 'ssn', 'Social security number is required' if ssn.blank?
        err 'ssn', 'Social security number is incorrectly formatted' if !ssn.blank? and !(ssn =~ /\A\d\d\d-?\d\d-?\d\d\d\d\Z/)
        err 'ssn', 'Social security number is invalid' if !ssn.blank? and ssn == '000-00-0000'
        err 'ssn', 'Social security number is invalid' if !ssn.blank? and ssn == '111-11-1111'
        err 'state_drivers_license', 'Please indicate if you have a NY drivers license' if state_drivers_license.nil?
        err 'law_violation', 'Please indicate if you have been convicted of a crime other than a minor traffic violation' if law_violation.nil?
        err 'pending_criminal_charges', 'Please indicate if you have pending criminal charges' if pending_criminal_charges.nil?
				err 'removed_employment', 'Please indicate if you have been removed from any type of employment' if removed_employment.nil?
        err 'applied_before', 'Please indicate if your have applied to Monroe County before' if applied_before.nil?
        err 'name_changed', 'Please indicate if your name has changed since your last application' if applied_before && name_changed.nil?
        err 'previous_first_name', 'Previous first name is required' if applied_before && name_changed && previous_first_name.blank?
        err 'previous_last_name', 'Previous last name is required' if applied_before && name_changed && previous_last_name.blank?
        update_attribute :general_complete, !@err
      when 'certifications'
        certifications.each { |o|
          err 'name', 'Name of Trade or Profession is required', o.id if o.name.blank?
        }
        if !license_requirement.blank? && certifications.empty?
          err 'license_requirement', "License Required: #{license_requirement}"
        end
        update_attribute :certifications_complete, !@err
      when 'education'
        err 'education', 'Education level is required' if education.blank?
        err 'education_grade', 'Please indicate the highest grade of school you completed' if ['lths', 'ged'].include?(education) and education_grade.blank?
        has_graduation_date = nil
        educations.each { |o|
          err 'school_name', 'Name of School is required', o.id if o.school_name.blank?
          err 'state', 'School state is required', o.id if o.state.blank?
          err 'major', 'Major is required', o.id if o.major.blank?
          err 'credits', 'Please indicate either semester or quarter credits completed', o.id if o.credits_semester.blank? and o.credits_quarter.blank?
          err 'degree', 'Type of degree / certificate received is required', o.id if o.degree.blank?
          has_graduation_date ||= o.graduation_date
        }
        if require_graduation_date && !has_graduation_date
        	err 'education_higher', 'At least one college and graduation date is required'
        end
        update_attribute :education_complete, !@err
      when 'training'
        trainings.each { |t|
          err 'description', 'Course / Program name is required', t.id if t.description.blank?
          err 'hours', 'Hours is required (please estimate)', t.id if t.hours.blank?
        }
        update_attribute :training_complete, !@err
      when 'employment'
        employments.each { |e|
          err 'name', 'Employer\'s name is required', e.id if e.name.blank?
          err 'address', 'Address is required', e.id if e.address.blank?
          err 'city', 'City, state & zip are required', e.id if e.city.blank? or e.state.blank? or e.zip.blank?
          err 'dates', 'Dates of employment are required', e.id if e.start_date.blank? or (e.end_date.blank? and !e.currently_employed)
          err 'salary', 'Salary is required', e.id if e.salary.blank?
          err 'hours', 'Hours worked per week is required and must be a number', e.id if e.hours.blank? or !(e.hours =~ /[0-9]/)
          err 'reason_left', 'Reason(s) for leaving is required', e.id if e.reason_left.blank?
          err 'title', 'Your job title is required', e.id if e.title.blank?
          err 'supervisor_name', 'Supervisor\'s name is required', e.id if e.supervisor_name.blank?
          err 'supervisor_title', 'Supervisor\'s title is required', e.id if e.supervisor_title.blank?
          err 'supervisor_phone', 'Supervisor\'s phone is required', e.id if e.supervisor_phone.blank?
          err 'description', 'Description of duties is required', e.id if e.description.blank?
        }
        update_attribute :employment_complete, !@err
      when 'veteran'
      	if vc_type == 'disabled' || vc_type == 'nondisabled' || vc_type == 'active'
      		err 'army_enlisted', 'Enlistment date is required' if army_enlisted.blank?
      		if vc_type != 'active' && army_to.blank?
      			err 'army_from', 'Active service dates are required'
      		elsif army_from.blank?
      			err 'army_from', 'Date of active service start (from) date is required'
      		end
      		err 'army_discharge_honorable', 'Please indicate if you were discharged under honorable conditions' if army_discharge_honorable.nil? && vc_type != 'active'
					err 'vc_used', 'Please indicate if you have previously been appointed from a civil service list where you were granted veterans credits' if vc_used.nil?
					if vc_used
						err 'vc_used_agency', 'Agency that established the eligible list is required' if vc_used_agency.blank?
					end
      	end
        update_attribute :veteran_complete, !@err
      when 'equal'
        update_attribute :equal_complete, !@err
      when 'attachments'
        update_attribute :attachments_complete, !@err
      when 'comments'
        update_attribute :comments_complete, !@err
      when 'supplement'
        if false && ask_loans && nonseasonal_fields?
          err 'loans_outstanding', 'Please answer yes or no to this question' if loans_outstanding.nil?
          err 'loans_default', 'Please answer yes or no to this question' if loans_default.nil?
          err 'loans_confirmed', 'You must check this box to continue' unless loans_confirmed
        end
        update_attribute :supplement_complete, !@err
      when 'typing'
        if ask_typing_waiver && nonseasonal_fields?
          err 'typing_waiver', 'Please select a reason why you are requesting the test be waived from the options below' if typing_waiver and !typing_waiver_1 and !typing_waiver_2
          err 'typing_waiver_2', 'Title and dept. are required' if typing_waiver and typing_waiver_2 and (typing_waiver_2_title.blank? or typing_waiver_2_dept.blank?)
        end
        update_attribute :typing_complete, !@err
      when 'waiver'
        if ask_fee_waiver && nonseasonal_fields?
          err 'waiver_requested', 'Please select at least one reason from the list below' if waiver_requested and !waiver_medicaid and !waiver_unemployed and !waiver_public_assistance and !waiver_ssi and !waiver_wia and !waiver_county and !waiver_social_workers
          #err 'waiver_public_assistance', 'Please select one of the public assistance types' if waiver_requested and !waiver_safety_net and !waiver_family_assistance and waiver_public_assistance
          err 'waiver_public_assistance', 'Please enter your case number' if waiver_requested and waiver_public_assistance and waiver_case_number.blank?
          err 'waiver_county_job', 'Job title and grade is required' if waiver_requested and waiver_county and waiver_county_job.blank?
          err 'waiver_social_workers_job', 'Job title and grade is required' if waiver_requested and waiver_social_workers and waiver_social_workers_job.blank?
          err 'waiver_legal', 'You must confirm that you have read the above portion of Section 50.5(b) of the Civil Service Law' if waiver_requested and !waiver_legal
          #err 'waiver_wia', 'Caseworker name and number are required' if waiver_requested and waiver_wia and (!waiver_wia_caseworker or !waiver_wia_phone)
        end
        update_attribute :waiver_complete, !@err
      when 'other_exams'
        if ask_crossfiler && nonseasonal_fields?
          other_exams.each { |o|
            err 'no', 'Exam number is required', o.id if o.no.blank?
            err 'name', 'Exam title is required', o.id if o.name.blank?
            err 'agency', 'Please select who is offering the exam', o.id if o.agency.blank?
          }
          unless other_exams.empty?
            err 'other_exams_admin', 'Please select who you would like to administer these exams' if other_exams_admin.blank?
          end
        end
        update_attribute :other_exams_complete, !@err
      when 'submit'
        err 'confirmed', 'You must check the box below to indicate you agree to the terms of this application' unless confirmed
        if self.save_view
          self.section = 'view'
          return
        end

        if can_submit?
          if waiver_requested or self.total == 0
            self.section = 'done' unless @err
          else
            self.section = 'done' if @new_payment.valid? and !@err and @new_payment.save
          end
        end

        if self.section == 'done'
        	if contact_via == 'email' && user.email =~ /@(hotmail|outlook).com$/i
        		self.contact_via = 'both'
        	end
          update_attributes :submit_complete => true, :submitted_at => DateTime.now.to_s
          find_residency
        else
          self.dont_redirect = true
        end
        return
    end
    self.section = 'view' if !@err || self.save_view
  end

  after_update :validate_section

  def err field, message, sub_id = nil
    SavedError.create :field => field, :applicant => self, :message => message, :section => section, :sub_id => sub_id
    @err = true
  end

  def new_payment= v
    @new_payment = Payment.new(v)
    @new_payment.applicant = self
    @new_payment.amount = total
  end

  def new_payment
    @new_payment ||= Payment.new(:amount => total, :applicant => self)
  end

  def can_submit?
    can = !exam_prices(true).empty?
    can &&= (saved_errors.empty? or (saved_errors.length == 1 and saved_errors[0].field == 'confirmed'))
    can &&= general_complete && certifications_complete && education_complete && training_complete && employment_complete
    if nonseasonal_fields?
      can &&= (veteran_complete || !ask_veterans)
      can &&= equal_complete
      #can &&= (supplement_complete || !ask_loans)
      can &&= (typing_complete || !ask_typing_waiver)
      can &&= (waiver_complete || !ask_fee_waiver)
      can &&= (other_exams_complete || !ask_crossfiler)
    end
    can &&= attachments_complete && comments_complete && exams_complete
    return can
  end

  alias_method :new_exam_prices, :exam_prices
  alias_method :new_certifications, :certifications
  alias_method :new_trainings, :trainings
  alias_method :new_educations, :educations
  alias_method :new_employments, :employments
  alias_method :new_other_exams, :other_exams

  attr :dont_redirect, true


  # Queries to make the searchable fields for find_residency
  #update parcels set address = concat(ST_NBR, ' ', LOCPREDIR, ' ', LOCSTNAME, ' ', LOCSTTYPE, ' ', LOCPOSTDIR);
  #update parcels set address_minus_no = concat(LOCPREDIR, ' ', LOCSTNAME, ' ', LOCSTTYPE, ' ', LOCPOSTDIR);
  #update parcels set address = trim(replace(address, '  ', ' '));
  #update parcels set address_minus_no = trim(replace(address, '  ', ' '));

  def find_residency
    a = residence_different ? res_address : address
    z = residence_different ? res_zip : zip
    a = a.gsub("STREET","ST");
    a = a.gsub("DRIVE","DR");
    a = a.gsub("AVENUE","AVE");
    a = a.gsub("ROAD","RD");
    a = a.gsub("LANE","LN");
    a = a.gsub("  "," ");

    a.delete! ','
    a.delete! '.'
    a.strip!
    p = Parcel.find :first, :conditions => ['address like ? and left(PAR_ZIP, 5) = ?', a, z[0, 5]]
    if p
      exp_fire = Fire.find_by_gis_name p.DISTRICT
      exp_school = School.find_by_gis_name p.SCH_NAME
      exp_swis = SwisCode.find_by_swis_code p.SWIS
      self.fire = exp_fire ? exp_fire.pstek_name : ''
      self.school = exp_school ? exp_school.pstek_name : ''
      self.village = exp_swis ? exp_swis.pstek_village_name : ''
      self.town = exp_swis ? exp_swis.pstek_town_name : ''
      save
    end
  end

  def seasonal?
    if @seasonal
      return @seasonal
    end
    seasonal_found = false
    other_found = false
    exams.each { |e|
      if e.exam_type.seasonal
        seasonal_found = true
      else
        other_found = true
      end
    }
    if seasonal_found && other_found
      @seasonal = 'mixed'
    elsif seasonal_found
      @seasonal = 'yes'
    else
      @seasonal = 'no'
    end
    return @seasonal
  end

  def seasonal_fields?
    seasonal? == 'mixed' || seasonal? == 'yes'
  end

  def nonseasonal_fields?
    seasonal? == 'mixed' || seasonal? == 'no'
  end

#	def contact_via
#		@contact_via || user.contact_via
#	end

#	def contact_via= v
#		@contact_via = v
#	end

#	def update_contact_via
#		user.update_attribute(:contact_via, @contact_via) if @contact_via
#	end

#	after_save :update_contact_via

end