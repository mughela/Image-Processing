require 'dotenv'
Dotenv.load
require 'aws-sdk'
require 'mini_magick'
require 'chunky_png'

Aws.config.update({region: "ap-southeast-2",credentials: Aws::Credentials.new(ENV["S3_ADMIN_AWS_KEY"],ENV["S3_ADMIN_AWS_PASS"])})
client = Aws::Rekognition::Client.new
img = "dh2_resize.png"
image = MiniMagick::Image.open(img)
x = image.width
y = image.height
puts "#{x} x #{y}"
wa = Array.new()
ha = Array.new()
la = Array.new()
ta = Array.new()

resp = client.detect_faces(image: { bytes: File.read(img) })
i = 1
resp.face_details.each do |face|
  puts "face #{i}"
  i += 1
  w = face.bounding_box.width
  h = face.bounding_box.height
  l = face.bounding_box.left
  t = face.bounding_box.top
  puts "width => #{w}"
  puts "height => #{h}"
  puts "left => #{l}"
  puts "top => #{t}"
  wp = (x * w).round(0)
  hp = (y * h).round(0)
  lp = (x * l).round(0)
  tp = (y * t).round(0)
  wa.push(wp)
  ha.push(hp)
  la.push(lp)
  ta.push(tp)
  puts "bounding box dimensions in pixels #{wp} x #{hp}"
  puts "left-top dimensions in pixels #{lp} x #{tp}"  
  puts ""
end

puts "weights",wa
puts "heights",ha
puts "left values",la
puts "top values",ta

if la.min - 100 < 0 
  new_left = 0
else
  new_left = la.min - 100
end
if ta.min - 100 < 0 
  new_top = 0
else
  new_top = ta.min - 100
end
puts "new left-top co-ordinates: #{new_left} x #{new_top}"
m = ta.index(ta.max)
if (ta.max + ha[m] - ta.min) + 150 > 630
  new_height=630
else
  new_height = (ta.max + ha[m] - ta.min) + 150
end
n = la.index(la.max)
if (la.max + wa[n] - la.min) + 150 > 1200
  new_width=0
else
  new_width = (la.max + wa[n] - la.min) + 150
end


#generating the boundary lines after scaling the bounding box
north = new_top
left_side = new_left
right_side = new_left + new_width
south = new_top + new_height

a1 = left_side
a2 = right_side
b1 = north
b2 = south
a = 0
b = 0
m = Array.new(40){Array.new(21)}
for i in (0...21)
    b += 30
  for j in (0...40)
    a += 30
    if (a >= a1) and (a <= a2)  and (b >= b1) and (b <= b2 )
      m[i][j] = 1
      else
        m[i][j] = 0
      end
   #puts a,b
   end
   a = 0   
end
for i in (0...21)
puts "#{m[i]}"
end

puts "new height => #{new_height}","new width => #{new_width}"
`convert -crop  #{new_width}x#{new_height}+#{new_left}+#{new_top} #{img} new_out.jpg`
puts `identify -ping -format '%w %h' new_out.jpg`


im = ChunkyPNG::Image.from_file("gradbot_resize.png")

heighth1 = im.dimension.height
widthw1  = im.dimension.width
pi = Array.new(1200){Array.new(630)}
heighth1.times do |i|
 widthw1.times do |j|
   arr = ChunkyPNG::Color.a(im[j,i])
   arr/=255.0
   pi[i][j]=arr.round(3)
 end
end

'''for i in (0...heighth1)
	puts "#{pi[i]}"
end'''



ss = 0
qq = 0
aa = 30
bb = 30
avg = Array.new(40){Array.new(21)}
for kk in (0...21)
	for ll in (0...40)
		sum = 0
		for ee in (ss...bb)
			for ff in (qq...aa)
				sum += pi[ee][ff]
			end
		end
		#puts sum
		#puts qq,aa,ss,bb
		#puts "\n"
		av = (sum / 900.0).round(2)
		avg[kk][ll] = av
		qq = aa
		aa += 30
	end
	ss = bb
	bb += 30
	qq = 0
	aa = 30
end

for i in (0...21)
	puts "#{avg[i]}"
end


sum1 = 0
for g in (0...21)
	for h in (0...40)
		sum1 += m[g][h] * avg[g][h]
	end
end
puts "with bottom gradient"
puts sum1


im = ChunkyPNG::Image.from_file("gradleft_resize.png")

heighth2 = im.dimension.height
widthw2 = im.dimension.width
pi = Array.new(1200){Array.new(630)}
heighth2.times do |i|
 widthw2.times do |j|
   arr = ChunkyPNG::Color.a(im[j,i])
   arr/=255.0
   pi[i][j]=arr.round(3)
 end
end

'''for i in (0...heighth2)
	puts "#{pi[i]}"
end'''

ss = 0
qq = 0
aa = 30
bb = 30
avg = Array.new(40){Array.new(21)}
for kk in (0...21)
	for ll in (0...40)
		sum = 0
		for ee in (ss...bb)
			for ff in (qq...aa)
				sum += pi[ee][ff]
			end
		end
		#puts sum
		#puts qq,aa,ss,bb
		#puts "\n"
		av = (sum / 900.0).round(2)
		avg[kk][ll] = av
		qq = aa
		aa += 30
	end
	ss = bb
	bb += 30
	qq = 0
	aa = 30
end

for i in (0...21)
	puts "#{avg[i]}"
end


sum2 = 0
for g in (0...21)
	for h in (0...40)
		sum2 += m[g][h] * avg[g][h]
	end
end

puts "with left gradient"
puts sum2