require 'nokogiri'
require 'pry'
require 'json'


courses = []
Dir.glob('1031/*.html').each do |filename|
	file = File.open(filename, 'r:utf-8')
  string = file.read
	document = Nokogiri::HTML(string.encode!("utf-8", :invalid => :replace, :undef => :replace, :replace => '?'))
  # .encode("utf-8",:invalid => :replace, :undef => :replace)
  if not document.css('h1').text.include?('103學年度第1學期')
    # puts "oh, no: #{filename}"
    next
  end

	document.css('table tr:not(:first-child)').each do |row|
    datas = row.css('td')
    times = nil
    location = nil

    if document.css('h1').text.include?('系所別: 通識教育中心')
      times =  datas[9] && datas[9].text
      location =  datas[10] && datas[10].text
      courses << {
        # grade: datas[0] && datas[0].text,
        grade: nil,
        code: datas[2] && datas[2].text,
        class_type: datas[3] && datas[3].text,
        name: datas[4] && datas[4].text && datas[4].text.strip,
        lecturer: datas[5] && datas[5].text && datas[5].text.strip,
        credits: datas[7] && datas[7].text && datas[7].text.to_i,
        required_or_elective: datas[8] && datas[8].text,
        # type: datas[10] && datas[10].text,
        outline: datas[12] && datas[12].css('a')[0] && datas[12].css('a')[0][:href],
        note: datas[13] && datas[13].text
      }
    else
      times = datas[8] && datas[8].text
      location = datas[9] && datas[9].text
      courses << {
        grade: datas[0] && datas[0].text,
        code: datas[1] && datas[1].text,
        class_type: datas[2] && datas[2].text,
        name: datas[3] && datas[3].text && datas[3].text.strip,
        lecturer: datas[4] && datas[4].text && datas[4].text.strip,
        credits: datas[6] && datas[6].text && datas[6].text.to_i,
        required_or_elective: datas[7] && datas[7].text,
        type: datas[10] && datas[10].text,
        outline: datas[11] && datas[11].css('a')[0] && datas[11].css('a')[0][:href],
        note: datas[12] && datas[12].text
      }
    end

    # do normalize
    periods = []
    if times && location
      times.split(' ').each do |time|
        m = time.match(/(?<d>[一二三四五六])(?<p>.+)/)
        if !!m
          m[:p].split(',').each do |period|
            chars = []
            chars << m[:d]
            chars << period
            chars << location
            periods << chars.join(',')
          end
        end
      end
    end
    courses.last[:periods] = periods

	end
end

File.open('courses.json','w'){|file| file.write(JSON.pretty_generate(courses))}
