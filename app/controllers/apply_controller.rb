class ApplyController < ApplicationController

	def mailtest
		Notifier.deliver_mailtest
		render :text => 'Mail Sent'
	end
	
	def errortest
		throw_errortest
	end

	def index
		@types = ExamType.find :all, :order => 'exam_types.`sort`'
	end
	
	def exam
		@obj = Exam.find params[:id]
		if (@obj.publish and @obj.publish > Time.now) or (@obj.exam_date and @obj.exam_date < Time.now) or !@obj.published
			# If the exam is not active, the user may still have an applicantion that includes this exam. Let them see it (javascript-disabled users should only be the ones who get here).
			unless @obj.applicants.to_a.find { |a| a.user == @current_user }
				render :nothing => true
			end
		end
	end
	
	def cart
		session[:cart] ||= SortedSet.new
		if request.post?
      if params[:add]
				if session[:cart].include? params[:add]
					e = Exam.find params[:add]
					flash[:notice] = "You have already added #{e.name} to your cart."
				else
					e = Exam.find params[:add]
					flash[:notice] = "#{e.name} has been added to your cart."
					session[:cart] << params[:add]
				end
			elsif params[:remove]
				e = Exam.find params[:remove]
				flash[:notice] = "#{e.name} has been removed from your cart."
				session[:cart].delete params[:remove]
			end
			redirect_to
		else
			@exams = session[:cart] ? Exam.find(:all, :conditions => ['id in (?)', session[:cart]]) : []
			@total = @exams.sum { |e| e.price.to_f }
			if @total > 0
				@payment_fee = @system.payment_fee
				@total += @payment_fee
			end
		end
	end
		
	def checkout
		if session[:cart].nil?
			redirect_to :action => :cart
		elsif @current_user
			a, flash[:notice] = Applicant.setup_and_create @current_user, session[:cart], @system.payment_fee
			Notifier.deliver_application_created a, url_for(:controller => :applicants, :action => :index, :id => nil)
			session[:cart] = nil
			redirect_to :controller => :applicants, :action => :view, :id => a.id
		else
			flash[:notice] = 'In order to apply online, you will need an account. Please either login or create a new account.'
			session[:after_login] = url_for({})
			redirect_to :controller => :account, :action => :index
		end
	end
	
	def noactivation
		session[:noactivation] = true
		flash[:notice] = 'Monroe County Civil Service - Apply Online.'
		redirect_to :action => :index
	end
	
	def testmail
		Notifier.deliver_testmail
		render :text => 'Email Sent'
	end
	
end