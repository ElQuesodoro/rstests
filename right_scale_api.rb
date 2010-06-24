require 'rubygems'
require 'right-scale-api'


def init(args)
	begin
		creds = {}
		passwdFile = File.open(args[0], "r")
		passwdFile.each do |line|
			line.strip!
			creds[line.split('=')[0]] = line.split('=')[1]	
		end
		return creds
	rescue => err
		puts "argument missing, probably the name of the credential file"
		puts " -- " +err
	end
end

def start_stop(myservers, nickname, arg)
	myservers["servers"].each do |server|
		#puts server["nickname"]
		if server["nickname"] == nickname
			#puts server["href"]
			print "server ID == #{server["href"].split('/')[-1]}\n"
			sid = server["href"].split('/')[-1]
			print "https://my.rightscale.com/api/acct/25875/servers/#{sid}/#{arg}\n"
			RightScaleAPI::Client.post("https://my.rightscale.com/api/acct/25875/servers/#{sid}/#{arg}")
		end
	end
end

def getIP(server)
	firstserver = server.pop
	#puts first.class
	firstsettings = RightScaleAPI::Client.get(firstserver["href"]+"/settings")
	return firstsettings
end

def showActiveServers(myservers)
	# outputting information from a server "get" based on "nickname"	

	myservers["servers"].each do |server|
		#puts server["nickname"]
		if server["state"] == "operational"
			puts server["nickname"]
			if server["nickname"] =~ /production-tomcat/
				print "server ID == #{server["href"].split('/')[-1]}\n"
				print "server nickname == #{server["nickname"]}\n"
				server_settings = getIP(server)
				puts ""
			end
		end
	end
end

def extricateGroupInfo(ip, query, type)

#puts ip, query, type

=begin

	This a pretty rough part of the ruby RS API due to the way that it returns the data.
	The XML format is also a little rough--pick your poison.
	It returns an array (group of server arrays) of hashes (information describing that array instance), 
	which in turn contain arrays (of the information about specific parts of that server array.

=end
	#puts "ip.class is " + ip.class.to_s
	#puts "ip.length is " + ip.length.to_s

	i = 0
	ip.each do |bob|
		addy, name = bob.split('###')
		puts addy
		puts name	
		if type == "server_arrays"
			array_settings = RightScaleAPI::Client.get(addy.to_s+"/instances")
			#puts "array_settings.class " + array_settings.class.to_s

			array_settings.each_key do |key|
				#puts array_settings[key].class
				array_settings[key].each do |server|
					server.each_key do |killmenow|
						# puts killmenow.to_s + " == " + server[killmenow].to_s	
						#if killmenow == "ip_address"
							puts killmenow.to_s + " == " + server[killmenow].to_s
						#end
					end
					puts "------------------------"
				end
				#print key.to_s + " == " + array_settings[key].to_s  + "\n"
				puts ""
				puts " * * * * * * * * * * * "
				puts ""
			end
		elsif type == "deployments"
			puts "bob"
		end	



		i = i + 1
	end


end

def checkREST(my_instances, instance_type)
	my_instances[instance_type].each do |server|
		server.each_key do |s|
			puts server[s].to_s + "  " + s.to_s	
		end
	end
#	my_instances.each_key do |key|
#		puts key
#		puts key.class
#		puts key.length
#	end


end

def extricateArrayIP(my_instances, instance_type, nickname)
#	puts my_instances, instance_type, nickname
	# pulling out a specific URL based on "nickname"

	target_server = []
	array_nicknames = []
	ip_list = []
	my_instances[instance_type].each do |server|
		server.each_key do |s|
			if server["nickname"] =~ /#{nickname}/
				ip_list << server["href"].to_s+"###"+server["nickname"].to_s
				#puts server["server_template_href"]
				#puts server["nickname"]
				target_server = server
			end
		end
	end 
	return ip_list.uniq!, target_server
end

args = ARGV

#puts args[0]
#puts args[1]

#begin
	creds = init(args)
	RightScaleAPI::Client.login creds["username"], creds["password"] 
	#types = [ "right_scripts", "servers", "deployments", "server_arrays" ]

		#my_instances = RightScaleAPI::Client.get("https://my.rightscale.com/api/acct/25875/#{type}")
		my_deployments = RightScaleAPI::Client.get('https://my.rightscale.com/api/acct/25875/deployments')
		my_servers = RightScaleAPI::Client.get('https://my.rightscale.com/api/acct/25875/servers')
		my_server_arrays = RightScaleAPI::Client.get('https://my.rightscale.com/api/acct/25875/server_arrays')
		my_right_scripts = RightScaleAPI::Client.get('https://my.rightscale.com/api/acct/25875/right_scripts')

		#instance_type = "right_scripts"
		#instance_type = "deployments"
		#nickname = "Production Tomcat"
		instance_type = "server_arrays"
		nickname = "production-tomcat"
		grouping=my_server_arrays
		ip_list, query= extricateArrayIP(grouping, instance_type, nickname)
		extricateGroupInfo(ip_list, query, instance_type)

		#puts server_array.class
		#puts server_array.length

		params = { "server_array[right_script_href]" => "https://my.rightscale.com/api/acct/25875/right_scripts/226724",  "server_array[server_template_hrefs]" => "https://my.rightscale.com/api/acct/25875/ec2_server_templates/58528"}
		#server_array["right_script_href"] = "https://my.rightscale.com/api/acct/25875/right_scripts/226724"
		#server_array["server_template_hrefs"] = "https://my.rightscale.com/api/acct/25875/ec2_server_templates/58528"
		#puts RightScaleAPI::Client.post('https://my.rightscale.com/api/acct/25875/server_arrays/6747/run_script_on_all.xml', "server_array[right_script_href]=https://my.rightscale.com/api/acct/25875/right_scripts/226724", "server_array[server_template_hrefs]=https://my.rightscale.com/api/acct/25875/ec2_server_templates/58528")
		#puts RightScaleAPI::Client.post('https://my.rightscale.com/api/acct/25875/server_arrays/6747/run_script_on_all.xml', params )
		#puts RightScaleAPI::Client.post('/api/acct/25875/server_arrays/6747/run_script_on_all', server_array )

	#start_stop(myservers, "tomcat_test2", args[1])
#rescue => err
#	puts " -- " + err.backtrace.to_s
#	puts "failed do to previous errors"
#end

ARRAY="https://my.rightscale.com/api/acct/25875/server_arrays/6747/run_script_on_all.xml"
TEMPLATE="https://my.rightscale.com/api/acct/25875/ec2_server_templates/58528"
RIGHTSCRIPT="https://my.rightscale.com/api/acct/25875/right_scripts/226724"


#puts `curl -c youveGotToBeFuckingKiddingMe -u #{creds["username"]}:#{creds["password"]}  https://my.rightscale.com/api/acct/25875/login?api_version=1.0`
#puts `curl -H 'X-API-VERSION: 1.0' -b youveGotToBeFuckingKiddingMe #{ARRAY} -d server_array[right_script_href]=#{RIGHTSCRIPT} -d server_array[server_template_hrefs]=#{TEMPLATE}`

#`curl -d right_script=https://my.rightscale.com/api/acct/25875/right_scripts/226724 -H 'X-API-VERSION: 1.0' -b youveGotToBeFuckingKiddingMe https://my.rightscale.com/api/acct/25875/server_arrays/6747/run_script_on_all`

