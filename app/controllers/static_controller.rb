class StaticController < ApplicationController
	require 'csv'
  def home
  end
  def make
  	@backupCtys=[]; @args=[];	@svs=[]

		@cas=tao_ds_ca(params[:begintime],params[:endtime],params[:interviewtime],params[:waittime],params[:lunchtime])
		if params[:svlist]
			f=File.open(params[:svlist].path,'r')
			@ctys=f.readline.chomp.split(',')[4..8].collect {|x| [
					x,0,0,[[],[],[],[],[],[],[],[],[],[]],0
				]	
			}
			f.each_line {
				|l|
				a=l.chomp.split(',')	
				bm_ctys=[]	
				if a[2]==nil&&a[3]==nil&&a[4]==nil&&a[5]==nil&&a[6]==nil
					bm_ctys= Array.new(5) { |i| [nil,i] }
					@ctys.each {|cty| cty[1]+=1}
				else
					2.upto(6) do |i|
						if a[i]!="" && a[i]!=nil && a[1]!=""
							bm_ctys<<[nil,i-2]				
							@ctys[i-2][1]+=1				
						end
					end		
				end
				
				if a[1]!=""
					case a[1][0..3]
					when "2013"
						a[1]="C"+a[1][-4..-1]
					when "2012"
						a[1]="B"+a[1][-4..-1]
					when "2011"
						a[1]="A"+a[1][-4..-1]
					else
						a[1]="V"+a[1][-4..-1]
					end	
					@svs<<[a[1],a[0],Array.new(bm_ctys),lich_khon(bm_ctys.count,ds_ca_co_the_join(a[7],a[8],@cas)),nil]			
				end
			}
			f.close

			@ctys.each {|cty|
				cty[2]=(cty[1]*1.0/@cas.count)#.ceil
			}

			max_sv_mot_ca=0
			@ctys.each {
				|cty|
				max_sv_mot_ca+=cty[2]
			}

			soluong_bms=Array.new(@ctys.count+1){
				|i|
				{danh_sach_sv:[],
				danh_sach_ca: [],
				so_cty_dangki: i}
			}
			@svs.each {	|sv| soluong_bms[sv[2].count][:danh_sach_sv]<<sv}
			print "Số lượng sinh viên: #{@svs.count}\n"
			soluong_bms.each {|bm| puts "#{bm[:danh_sach_sv].count} sinh viên đăng kí #{bm[:so_cty_dangki]} công ty."}
			@svs=@svs.shuffle.sort_by! {|sv| sv[2].count + (sv[3].count)<<7}
			r=[0,0,0]
			begin
			  r=trau_code r[0],r[1],r[2]
			end until r==nil
		else
		end #if params[:svlist]
		#inra @ctys if @ctys
		#inrafile @ctys if @ctys
		#inrafile2 @ctys if @ctys		
  	respond_to do |f|
  		f.html
  		f.js
  	end
  end
  private
	#tra ve mang cac ca phong van voi cau truc mot ca nhu sau [thoigianbatdau,thoigianketthuc]
	def tao_ds_ca begin_time="9h00",end_time="17h25",thoigianphongvan="40",thoigiannghi="5",thoigiannghitrua="60"			
		begin_t,end_t,phongvan_t,nghi_t,nghitrua_t=begin_time.to_time,end_time.to_time,thoigianphongvan.to_i,thoigiannghi.to_i,thoigiannghitrua.to_i	
		a=[]
		so_ca=(end_t-begin_t-nghitrua_t+nghi_t)/(phongvan_t+nghi_t)
		temp=begin_t
		1.upto(so_ca) {|i| a<<[temp,temp+= phongvan_t];temp+= nghi_t + i==so_ca>>1+1 ? nghitrua_t : 0}
		return a
	end

	#tra ve mang chua index cua cac ca phong van co the tham gia
	#tham so la ds cac ca phong van va khoang thoi gian ma sinh vien co the tham gia 
	def ds_ca_co_the_join begin_time="9h00",end_time="17h25",cas
		begin_time||="9h00"
		end_time||="17h25"
		b,e=begin_time.to_time,end_time.to_time
		return 0.upto(cas.size-1).select {|i| b<=cas[i][0]&&cas[i][1]<=e }	
	end

	def inra ctys,masinhvien=nil
		print "================================================================\n"
		print "  | Ca 1| Ca 2| Ca 3| Ca 4| Ca 5| Ca 6| Ca 7| Ca 8| Ca 9|Ca 10|\n"
		# print "================================================================\n"
		ctys.each.with_index {
			|cty,i|
			print "_______________________________________________________________\n"
			0.upto(cty[2]) {|j|
				print j==0 ? "#{i} |" : "  |"
				cty[3].each {
					|list_svs|
					if list_svs[j]
						if masinhvien
							print list_svs[j][0]!=masinhvien ? "#{list_svs[j][0]}|" : "@@@@@|"
						else
							print "#{list_svs[j][0]}|"
						end
					else
						print "     |"					
					end
				}
				print "\n"
			}		
		}
		print "================================================================\n"
	end

	def inrafile ctys,masinhvien=nil
		f=File.open('timetable.csv','w')	
		f.write ",Ca 1,,Ca 2,,Ca 3,,Ca 4,,Ca 5,,Ca 6,,Ca 7,,Ca 8,,Ca 9,,Ca 10,\n"	
		ctys.each.with_index {
			|cty,i|		
			0.upto(cty[2]) {|j|
				f.write j==0 ? "#{cty[0]}," : ","
				cty[3].each {
					|list_svs|
					if list_svs[j]
						f.write "#{list_svs[j][0]},#{list_svs[j][1]},"				
					else
						f.write ",,"
					end
				}
				f.write "\n"
			}
			f.write ",,,,,,,,,,,,,,,,,,,,\n"		
		}
		f.write ",,,,,,,,,,\n"
		f.write ",,Ca 1,Ca 2,Ca 3,Ca 4,Ca 5,Ca 6,Ca 7,Ca 8,Ca 9,Ca 10\n"
		@svs.each {|sv|
			tmp=Array.new(10,nil)
			sv[2].each {
				|x|
				tmp[x[0]-1]=ctys[x[1]][0]
			}
			f.write "#{sv[0]},#{sv[1]},"
			tmp.each {|x|
			 	if x 
			 		f.write "#{x},"
			 	else
			 		f.write ","
			 	end
			}
			f.write "\n"
		}	
		f.close
	end
	def inrafile2 ctys,masinhvien=nil
		f=File.open('interview-timetable.csv','w')	
		f.write ",,"
		ctys.each {	|cty| f.write "#{cty[0].capitalize}さま,,"	}
		f.write "\n"
		f.write "開始時間,終了時間,"
		ctys.count.times {|i| f.write "学籍番号,名前,"}
		f.write "\n"
		@cas.each.with_index {|ca,j|
			flag_in_time=true
			0.upto(7) {|i|
				if flag_in_time
					f.write "#{ca[0].to_time},#{ca[1].to_time},"
					flag_in_time=false
				else
					f.write ",,"
				end
				ctys.each {|cty|
					if cty[3][j][i]
						f.write "#{cty[3][j][i][0]},#{cty[3][j][i][1]},"				
					else
						f.write ",,"
					end				
				}
				f.write "\n"
			}
		}	
		f.close
	end

	#tra ve so lan duoc nghi ngoi giua cac ca phong van
	#tham so la danh sach cac ca ma sinh vien da tham gia
	def thoi_gian_nghi_ngoi a	
		(a.size-1).times.count {|i| a[i]+1<a[i+1] || a[i]==5}
	end

	#lich_khon tra ve mang chua nhung kha nang xep lich pv cho 1 sv nhu the nao tuy theo so lg cty dang ki va thoi gian dang ki
	#tham so num la so luong cty ma sinh vien dang ki, array la ds cac ca ma sinh vien co the tham gia
	def lich_khon num,array 
		a=[]
		max=array.count-1
		if (num<<1)>=(max+1)		
			case max+1-num
			when 0
				a<<Array.new(array)
			when 1
				0.upto(max){|i|
					t=Array.new(array)
					t.delete_at(i)
					a<<t
				}
			when 2
				0.upto(max-1){|i|
					(i+1).upto(max) {|j|				
						t=Array.new(array)				
						t.delete_at(i) 				
						t.delete_at(j-1)
						a<<t
					}			
				}
			when 3
				0.upto(max-2){|i|
					(i+1).upto(max-1) {|j|
						(j+1).upto(max) {|k|
							t=Array.new(array)				
							t.delete_at(i) 				
							t.delete_at(j-1)
							t.delete_at(k-2)
							a<<t
						}				
					}			
				}
			when 4
				0.upto(max-3){|i|
					(i+1).upto(max-2) {|j|
						(j+1).upto(max-1) {|k|
							(k+1).upto(max) {|l|
								t=Array.new(array)				
								t.delete_at(i) 				
								t.delete_at(j-1)
								t.delete_at(k-2)
								t.delete_at(l-3)
								a<<t
							}
						}				
					}			
				}
			when 5
				0.upto(max-4){|i|
					(i+1).upto(max-3) {|j|
						(j+1).upto(max-2) {|k|
							(k+1).upto(max-1) {|l|
								(l+1).upto(max) {|m|
									t=Array.new(array)				
									t.delete_at(i) 				
									t.delete_at(j-1)
									t.delete_at(k-2)
									t.delete_at(l-3)
									t.delete_at(m-4)
									a<<t
								}
							}
						}				
					}			
				}		
			else
			end
		else		
			case num	
			when 1			
				0.upto(max){|i|				
					a<<array.values_at(i)
				}
			when 2
				0.upto(max-1){|i|
					(i+1).upto(max) {|j|					
						a<<array.values_at(i,j)
					}			
				}
			when 3
				0.upto(max-2){|i|
					(i+1).upto(max-1) {|j|
						(j+1).upto(max) {|k|
							a<<array.values_at(i,j,k)
						}				
					}			
				}
			when 4
				0.upto(max-3){|i|
					(i+1).upto(max-2) {|j|
						(j+1).upto(max-1) {|k|
							(k+1).upto(max) {|l|
								a<<array.values_at(i,j,k,l)
							}
						}				
					}			
				}
			when 5
				0.upto(max-4){|i|
					(i+1).upto(max-3){|j|
						(j+1).upto(max-2) {|k|
							(k+1).upto(max-1) {|l|
								(l+1).upto(max) {|m|
									a<<array.values_at(i,j,k,l,m)
								}
							}
						}				
					}			
				}		
			else
			end
		end
		return a.sort_by {|x| -(thoi_gian_nghi_ngoi x)}
	end
	
	def trau_code sinhvienhientai,lichhientai,hoanvihientai	
		if @svs 
			if sinhvienhientai==@svs.count
				puts "Chày cối thành công!"
				return nil
			else
				sv=@svs[sinhvienhientai]
				if lichhientai==sv[3].count				
					@ctys=Array.new(@backupCtys.pop)				
					sinhvienhientai,lichhientai,hoanvihientai=@args.pop				
					return [sinhvienhientai,lichhientai,hoanvihientai+1]
				else
					array=sv[3][lichhientai]
					puts "Fatal error!" if sv[2].count!=array.count
					if hoanvihientai==array.permutation.to_a.count					
						return [sinhvienhientai,lichhientai+1,0]
					else	
						a=array.permutation.to_a[hoanvihientai]							
						flag=true
						0.upto(a.count-1) {|i|
							congty_dang_xet=@ctys[ (sv[2][i][1]) ]						
								if congty_dang_xet[3][a[i]-1].count>=congty_dang_xet[4]/10+1
								 flag=false
								 break
								end					
							
						}					
						if flag==true
							
							@backupCtys<<Array.new(@ctys.count) {|j| [
										String.new(@ctys[j][0]),@ctys[j][1],@ctys[j][2],
										Array.new(@cas.count) { |i| Array.new(@ctys[j][3][i]) },
										@ctys[j][4]
									]								
								}						
							
							@args<<[sinhvienhientai,lichhientai,hoanvihientai]						
							sv[4]=a

							0.upto(a.count-1) {|i|
								t=sv[2]
								id_cty=t[i][1]
								t[i][0]=a[i]						
															
								@ctys[ id_cty ][3][ a[i]-1 ]<<[sv[0],sv[1]]
								@ctys[ id_cty ][4]+=1
								
							}						
							return [sinhvienhientai+1,0,0]											
						else						
							return [sinhvienhientai,lichhientai,hoanvihientai+1]
						end	
					end
				end
			end
		else
			puts "Không thể xếp nổi!"
			return nil
		end		
	end	
end
class String	
	def to_time
		a=split('h')
		return a.count==2 ? a[0].to_i*60+a[1].to_i : 0
	end
end
class Fixnum
	def to_time
		return "#{self/60}h#{self%60}"
	end	
end
