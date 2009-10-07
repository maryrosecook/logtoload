require 'net/http'
require 'uri'

LOG_FILENAME = ARGV[0]
URL_LIST_FILENAME = ARGV[1]
LOAD_TEST_XML_FILENAME = ARGV[2]

PARAMS = "params"
NO_PARAMS = "no_params"

def read(filename)
  str = ""
  file = File.new(filename, "r")
  while line = file.gets
    str += line
  end
  
  return str
end

def xml_frag(url_type, i)
  return read(url_type + i.to_s + ".txt")
end


if LOG_FILENAME
  # get all urls requested in log file
  urls = {}
  urls[PARAMS] = []
  urls[NO_PARAMS] = []
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
        line.match(/\?/) ? urls[PARAMS] << line.strip : urls[NO_PARAMS] << line.strip
      end
    end
  
    i += 1
  end

  # retain unique urls
  unique_urls = {}
  for url_type in urls.keys
    unique_urls[url_type] = urls[url_type].uniq
  end

  # write unique_urls to file
  if URL_LIST_FILENAME
    File.open(URL_LIST_FILENAME, 'w') do |f| 
      for url_type in urls.keys
        for url in urls[url_type]
          f.write(url + "\n") 
        end
      end
    end
  end

  # read in xml fragments for the different types of URL
  no_params1 = xml_frag(NO_PARAMS, 1)
  no_params2 = xml_frag(NO_PARAMS, 2)
  no_params3 = xml_frag(NO_PARAMS, 3)
  params1 = xml_frag(PARAMS, 1)
  params2 = xml_frag(PARAMS, 2)
  params3 = xml_frag(PARAMS, 3)
  params4 = xml_frag(PARAMS, 4)
  params5 = xml_frag(PARAMS, 5)

  # for each url, make a new piece of xml and add it onto xml_str
  i = 0
  xml_str = ""
  for url_type in urls.keys
    for url in urls[url_type]
      if url_type == NO_PARAMS
        xml_str += no_params1 + url + no_params2 + url + no_params3 + "\n\n"
      elsif url_type == PARAMS
        xml_str += params1 + url + params2 
        
        # add special xml for each param
        uri = URI.parse(url)
        for param_pair in uri.query.split("&")
          name_and_value = param_pair.split("=")            
          param_name = name_and_value[0]
          param_value = name_and_value[1]
          xml_str += params3.gsub(/paramname/, param_name.to_s).gsub(/paramvalue/, param_value.to_s)
        end
      
        xml_str += params4 + url + params5 + "\n\n"
        i += 1
      end
    end
  end

  # write xml_str to file
  if LOAD_TEST_XML_FILENAME
    File.open(LOAD_TEST_XML_FILENAME, 'w') do |f| 
      f.write(xml_str) 
    end
  end
else
  puts "You need to specify a log filename."
end