require 'resolv'
require 'csv'
require 'logger'
require 'dalli'
DNS = Resolv::DNS.new(nameserver: ['8.8.8.8', '8.8.4.4'])
LOG = Logger.new("logfile.log")
OUT = CSV.open("outfile.csv", 'w+')
HEADERS = %w(domain server_name server soa edns do edns1 optlist).map(&:to_sym)
OUT << HEADERS

CACHE = Dalli::Client.new('localhost:11211')

if `dig -v 2>&1` =~ (/^DiG 9.1[1,2]/)
  puts "DiG OK"
else
  puts "DiG must be version 9.11 or 9.12"
  exit
end

def test_domain(domain)
  print "Determining nameservers...  "
  ns_records = DNS.getresources(domain, Resolv::DNS::Resource::IN::NS).map(&:name).map(&:to_s)
  LOG.debug(ns_records)
  puts ns_records.join(", ")
  ns_ips = ns_records.map{|ns| DNS.getaddresses(ns).reject{|i| i.is_a?(Resolv::IPv6)}.map(&:to_s) }.flatten.uniq
  LOG.debug(ns_ips)
  return ns_ips.map {|i| test_server domain, i}
end

def test_server(domain,server)
  if res = CACHE.get(server)
    puts "Cached resonse for #{domain} on #{server}!"
    res[domain] = domain
    return res
  end
  res = {
    domain:   domain,
    server:   server,
    server_name: nil,
    soa:      "FAIL",
    edns:     "FAIL",
    do:       "FAIL",
    edns1:    "FAIL",
    optlist:  "FAIL"
  }
  begin
    res[:server_name] = DNS.getname(server).to_s
  rescue
  end
  print "Testing #{domain} against #{server}."
  soa = `dig soa #{domain} @#{server} +noedns +noad +norec`
  LOG.debug(soa)
  if soa && $?.success?
    print '.'
    res[:soa] = "PASS"
  else
    puts "FAILED! - Server not configured for domain."
    return res
  end

  edns_ok = `dig soa #{domain} @#{server} +edns=0 +nocookie +noad +norec`
  LOG.debug(edns_ok)
  if edns_ok && $?.success?
    print '.'
    res[:edns] = "PASS"
  else
    puts "FAILED! - Server unable to supply EDNS response."
    CACHE.set(server, res)
    return res
  end

  do_test = `dig soa #{domain} @#{server} +edns=0 +nocookie +noad +norec +dnssec`
  if do_test && $?.success?
    print '.'
    res[:do] = "PASS"
  else
    puts "FAILED! - Server unable to supply DO Bit."
    CACHE.set(server, res)
    return res
  end

  edns1_test = `dig soa #{domain} @#{server} +edns=1 +noednsneg +nocookie +noad +norec`
  LOG.debug(edns1_test)
  if edns1_test && $?.success?
    if edns1_test =~ /status: BADVERS/
      print "."
      res[:edns1] = "PASS"
    else
      res[:edns1] = "WARN"
      print "WARNING - Server accepted ENSv1 "
    end
  else
    print '.'
  end

  optlist = `dig soa #{domain} @#{server} +edns=0 +noad +norec +nsid +subnet=0.0.0.0/0 +expire +cookie=0102030405060708`
  LOG.debug(optlist)
  if optlist && $?.success?
    status = optlist.match(/status: (\w*)/)[1]
    if status == "NOERROR"
      res[:optlist] = "PASS"
    else
      res[:optlist] = status
    end
  end
  puts ".OK!"
  CACHE.set(server, res)
  return res
end

CSV.foreach("infile.csv", headers: true) do |row|
  test_domain(row['domain']).each do |result|
    OUT << HEADERS.map{|k| result[k]}
  end
end
