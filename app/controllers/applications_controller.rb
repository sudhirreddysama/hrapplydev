class ApplicationsController < ApplicationController

	before_filter :rl, :except => :attachment; def rl; require_level 10; end
	before_filter :st; def st; @title = 'Exam / Job Applications'; end
	
	def index
		@filter = params[:filter] || flash[:applications_filter]
		@filter = {} if !@filter or @filter[:clear]
		flash[:applications_filter] = @filter
		cond = get_search_conditions @filter[:search], {'applicants.id' => :left, 'applicants.first_name' => :like, 'applicants.last_name' => :like}
		#cond << 'applicants.submit_complete = 1'
		@objs = Applicant.paginate({:include => [{:exam_prices => :exam}, :user],
			:page => params[:page],
			:conditions => get_where(cond), 
			:order => 'ifnull(applicants.submitted_at, applicants.created_at) desc'})
	end
	
	def view
		@noform = true
		@obj = Applicant.find params[:id]
		@obj.section = params[:action]
		render :template => "applicants/#{params[:action]}"
	end
	
	alias_method :general, :view
	alias_method :exams, :view
	alias_method :certifications, :view
	alias_method :education, :view
	alias_method :training, :view
	alias_method :employment, :view
	alias_method :veteran, :view
	alias_method :equal, :view
	alias_method :typing, :view
	alias_method :waiver, :view
	alias_method :attachments, :view
	alias_method :comments, :view
	alias_method :supplement, :view
	alias_method :other_exams, :view
	alias_method :submit, :view

	def user_flip
		session[:current_user_id] = params[:id]
		render :text => 'FLIP!'
	end

end