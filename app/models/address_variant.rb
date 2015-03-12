class AddressVariant < ActiveRecord::Base

	def self.generate adr
		parts = adr.split ' '
		words = find(:all, :conditions => ['word in (?)', parts]).group_by &:word
		adr2 = [' ' + adr]
		words.each { |w, vars|
			w = ' ' + w
			adr3 = []
			adr2.each { |a|
				vars.each { |v|
					adr3 << a.sub(w, ' ' + v.variant)
				}
			}
			adr3 << a.sub(w, '')
			adr2 += adr3
		}
		return adr2.strip
	end

end