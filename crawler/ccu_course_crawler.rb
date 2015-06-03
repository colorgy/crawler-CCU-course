require 'rubygems/package'
require 'archive/tar/minitar'
require 'zlib'
require 'open-uri'
require 'nokogiri'
require 'pry'
require 'json'


class CcuCourseCrawler
  include Archive::Tar

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @download_path = "http://kiki.ccu.edu.tw/~ccmisp06/Course/zipfiles/"
    @filename = "#{@year-1911}#{@term}.tgz"
    @dir_name = "#{@year-1911}#{@term}"
  end

  def courses
    @courses = []

    if not Dir.exist?(@dir_name)
      File.write(@filename, open("#{@download_path}#{@filename}").read)
      tgz = Zlib::GzipReader.open(@filename)
      Minitar.unpack tgz, @dir_name
    end

    @courses = Dir.glob("#{@dir_name}/*.html").map do |filename|
      puts filename
      document = Nokogiri::HTML(File.read(filename).force_encoding('utf-8'))
      if not document.css('h1').text.include?("#{@year-1911}學年度第#{@term}學期")
        []
      else
        department = nil
        document.css('h1').text.match(/系所別\:\ (?<dep>.+)/) {|m| department = m[:dep]}

        document.css('table tr:not(:first-child)').map do |row|
          datas = row.css('td')
          times = nil
          location = nil

          # binding.pry

          times =  datas[8] && datas[8].text
          location =  datas[9] && datas[9].text
          group_code = datas[2] && datas[2].text

          course_days = []
          course_periods = []
          course_locations = []

          if times && location
            times.split(' ').each do |time|
              time.match(/(?<d>[DAYS.keys.join])(?<p>.+)/) do |m|
                m[:p].split(',').each do |period|
                  course_days << DAYS[m[:d]]
                  course_periods << period
                  course_locations << location
                end
              end
            end
          end

          course = {
            code: datas[2] && "#{@year}-#{@term}-#{datas[1].text}-#{group_code}",
            group_code: group_code,
            name: datas[3] && datas[3].text && datas[3].text.strip,
            lecturer: datas[4] && datas[4].text && datas[4].text.strip,
            department: department,
            credits: datas[6] && datas[6].text && datas[6].text.to_i,
            required: datas[7] && datas[7].text.include?('必'),
            url: datas[11] && datas[11].css('a')[0] && datas[11].css('a')[0][:href],
            day_1: course_days[0],
            day_2: course_days[1],
            day_3: course_days[2],
            day_4: course_days[3],
            day_5: course_days[4],
            day_6: course_days[5],
            day_7: course_days[6],
            day_8: course_days[7],
            day_9: course_days[8],
            period_1: course_periods[0],
            period_2: course_periods[1],
            period_3: course_periods[2],
            period_4: course_periods[3],
            period_5: course_periods[4],
            period_6: course_periods[5],
            period_7: course_periods[6],
            period_8: course_periods[7],
            period_9: course_periods[8],
            location_1: course_locations[0],
            location_2: course_locations[1],
            location_3: course_locations[2],
            location_4: course_locations[3],
            location_5: course_locations[4],
            location_6: course_locations[5],
            location_7: course_locations[6],
            location_8: course_locations[7],
            location_9: course_locations[8],
            note: datas[13] && datas[13].text,
          }

          # if not document.css('h1').text.include?('系所別: 通識教育中心')
          #   course[:grade] = datas[0] && datas[0].text
          #   course[:type] = datas[10] && datas[10].text
          # end

          course
        end # document.css('table tr:not(:first-child)').map
      end # if not document.css('h1').text.include?
    end.inject { |arr, nxt| arr.concat nxt }

    File.write('courses.json', JSON.pretty_generate(@courses))
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end

cc = CcuCourseCrawler.new(year: 2014, term: 1)
cc.courses
