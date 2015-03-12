class ExamsController < ApplicationController
	
	before_filter :rl; def rl; require_level 10; end

	def index
		@filter = params[:filter] || flash[:exams_filter]
		@filter = {} if !@filter || @filter[:clear]
		flash[:exams_filter] = @filter
		cond = get_search_conditions @filter[:search], {'exams.no' => :like, 'exams.name' => :like}
		@objs = Exam.paginate :page => params[:page], :conditions => get_where(cond), :order => 'exams.name asc'
	end
	
	def view
		@obj = Exam.find params[:id], :include => {:exam_prices => :applicant}, :order => 'applicants.submitted_at desc'
	end
	
	def new
		@obj = Exam.new params[:obj]
		if request.post?
			if @obj.save
				flash[:notice] = 'Exam has been saved.'
				redirect_to :action => :view, :id => @obj.id
			end		
		elsif params[:internal_id]
			e = DB.query('select * from mccs.exams where id = %d', params[:internal_id].to_i).fetch_hash
			if e
				@obj.no = e.exam_no
				@obj.name = e.title
				@obj.price = e.fee
				@obj.publish = e.publish_at
				@obj.deadline = e.deadline
				@obj.exam_type_id = 1
				@obj.exam_date = e.given_at				
			end
		end
	end
	
	def edit
		@obj = Exam.find params[:id]
		if request.post? and @obj.update_attributes params[:obj]
			flash[:notice] = 'Exam has been saved.'
			redirect_to :action => :view, :id => @obj.id
		end
	end
	
	def delete
		@obj = Exam.find params[:id]
		if request.post? and @obj.destroy
			flash[:notice] = 'Exam has been deleted.'
			redirect_to :action => :index
		end
	end

end