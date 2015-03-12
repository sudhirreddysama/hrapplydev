# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def nl2br s
	  s.to_s.gsub(/\n/, '<br />')
 	end
 	
	def nl2br_h s
 		nl2br h(s)
 	end
 	
	def m n
		number_to_currency n.to_f, :unit => '$'
	end

	#
	# Renders tabs. Tabs will be current if p1 matches whats in params. p2 will also be sent to link_to
	# but don't effect whether or not the tab is open.
	#
	def tab txt, p1, p2 = {}, opt = {}
		opt[:class] = 'current' if p1.all? { |k, v| !v or params[k].to_s == v.to_s }
		link_to txt, p1.merge(p2), opt
	end
	
	def yn v
		v ? 'yes' : 'no'
	end
	
	
	
	
	
	
	
	
=begin	
	def text_area_tag *args
		unless @noform
			super *args
		else
			return h args[1]
		end
	end
	
	def calendar_date_select_tag *args
		unless @noform
			super *args
		else
			return args[1].strftime('%B %d, %Y') rescue nil
		end
	end
	
	def text_field_tag *args
		unless @noform
			super *args
		else
			return h args[1]
		end
	end
	
	def radio_button_tag *args
		unless @noform
			super *args
		else
			return image_tag(args[2] ? 'checked.gif' : 'unchecked.gif', :size => '16x16', :style => 'border: none;')
		end
	end
	
	def options_for_select *args
		unless @noform
			super *args
		else
			opt = args[0].rassoc(args[1])
			return opt ? opt[0] : args[0][0][0] 		
		end
	end
	
	def select_tag *args
		unless @noform
			super *args
		else
			return args[1]
		end
	end
=end
	
	def text_field *args
		if @noform
			args[2] ||= {}
			args[2][:readonly] = true
		end
		super *args
	end
	
	def calendar_date_select *args
		if @noform
			args[2] ||= {}
			args[2][:readonly] = true
		end
		super *args
	end
	
	def check_box *args
		if @noform
			args[2] ||= {}
			args[2][:disabled] = true
		end
		super *args
	end
	
	def radio_button *args
		if @noform
			args[3] ||= {}
			args[3][:disabled] = true
		end
		super *args
	end
	
	def text_area *args
		if @noform
			args[2] ||= {}
			args[2][:readonly] = true
		end
		super *args
	end
	
	def select *args
		if @noform
		p args
			args[4] ||= {}
			args[4][:disabled] = true
		end
		super *args
	end
	
	def submit_tag *args
		unless @noform
			super *args
		else
			return ''
		end
	end
	
	def comma_h *args
		args.collect { |s| s.to_s.strip }.reject(&:blank?).collect { |v| h v }.join ', '
	end
	
	def err field, sub_id = nil
		e = @obj.saved_errors.to_a.find { |e| e.section == @obj.section && e.field == field && e.sub_id == sub_id }
		if e
			return '<div class="field-error">' + h(e.message) + '</div><div class="clear"></div>'
		end
	end
	
	def has_err sub_id = nil
		@obj.saved_errors.to_a.find { |e| e.section == @obj.section && e.sub_id == sub_id }
	end
	
	def new_page
		if @first_page
			return '<!-- NEW PAGE -->'
		end
		@first_page = true
		return ''
	end
	
end
