LOG_FILENAME = ARGV[0]
URL_LIST_FILENAME = ARGV[1]
LOAD_TEST_XML_FILENAME = ARGV[2]
EXCLUDE_URLS_WITH_QUESTION_MARKS = Boolean(ARGV[3])

def read_file_to_str(filename)
  str = ""
  file = File.new(filename, "r")
  while line = file.gets
    str += line
  end
  
  return str
end

def Boolean(string)
  return true if string == true || string =~ /^true$/i
  return false if string == false || string.nil? || string =~ /^false$/i
  raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
end

if LOG_FILENAME
  # get all urls requested in log file
  urls = []
  file = File.new(LOG_FILENAME, "r")
  i = 0
  while line = file.gets
    if i > 0
      line = line.gsub(/[^\]]*\]/, '')
      line = line.gsub('"', '')
      line = line.gsub(/ HTTP\/.*/, "")
      line = line.gsub(/PROPFIND.*/, "")
      line = line.gsub(/GET /, "")
      line = line.gsub(/HEAD /, "")
      line = line.gsub(/POST /, "")
      line = line.gsub(/actionToken=[^\&]*\&/, "&")
      line = line.strip
      if line && line.length > 0
        urls << line.strip unless EXCLUDE_URLS_WITH_QUESTION_MARKS && line.match(/\?/)
      end
    end
  
    i += 1
  end

  # retain unique urls
  unique_urls = urls.uniq

  # write unique_urls to file
  if URL_LIST_FILENAME
    File.open(URL_LIST_FILENAME, 'w') do |f| 
      for url in unique_urls
        f.write(url + "\n") 
      end
    end
  end

  # put xml pieces into vars
  part_1 = read_file_to_str("1.txt")
  part_2 = read_file_to_str("2.txt")
  part_3 = read_file_to_str("3.txt")

  # for each url, make a new piece of xml and add it onto xml_str
  xml_str = ""
  for url in unique_urls
    xml_str += part_1 + url + part_2 + url + part_3 + "\n\n"
  end

  # write xml_str to file
  if LOAD_TEST_XML_FILENAME
    File.open(LOAD_TEST_XML_FILENAME, 'w') do |f| 
      f.write(xml_str) 
    end
  end
end
