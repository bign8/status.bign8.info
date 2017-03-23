import json
import urllib2
from os.path import expanduser

ENVZ = 'envz'
SVCZ = 'svcz'
NOOP = 'noop'
required_keys = [ENVZ, SVCZ]
super_secret_proxy_tmpl = "http://status.bign8.info/proxy?url={}"
widget_icon = u"\u03F2".encode('utf-8')

def main():
	try:
		config = get_config('~/.bign8status.conf')
		print(healthcheck_to_bitbar(healthcheck(config)))
	except Exception as err:
		bitbar_error(err)

def get_config(location):
	config_location = expanduser(location)
	with open(config_location) as file:
		config = json.load(file)

	# Are all the required keys present?
	for key in required_keys:
		if key not in config or not config.get(key):
			raise Exception('{}: No {} found, an {} is required'.format(config_location, key, key))

	# Do the services have (mostly) valid URLs?
	for key, value in config[SVCZ].iteritems():
		if '$' not in value:
			raise Exception('{}: no $ present for injecting an environment, is $ missing?'.format(value))

		if not urllib2.urlparse.urlparse(value).scheme:
			raise Exception('{}: is not a valid svcz URL for {}. Is the protocol missing?'.format(value, key))

	# Has the no-ops really been far even as decided to use even go want to do look more like?
	for noop in config[NOOP] or []:
		parts = noop.split('-')
		if len(parts) == 1:
			raise Exception('{}: is not a valid noop: requires format "svcz-envz"'.format(noop))

		if not config[SVCZ].get(parts[0]) or not config[ENVZ].get(parts[1]):
			raise Exception('{}: is not a valid noop: requires format "svcz-envz"'.format(noop))
	
	return config

def healthcheck(config):
	result = {}
	for envName, envURL in config[ENVZ].iteritems():
		result[envName] = {}
		for svcName, svcURL in config[SVCZ].iteritems():
				
			# Don't do NOOPs 
			if ("{}-{}".format(svcName, envName)) in config[NOOP]:
				continue

			try:
				url = svcURL.replace('$', envURL)
				resp = urllib2.urlopen(super_secret_proxy_tmpl.format(url))
			except urllib2.HTTPError as e:
				result[envName][svcName] = e.code
			except urllib2.URLError as e:
				result[envName][svcName] = 'XXXX'
			else:
				# TODO - this could be 20X, not sure
				result[envName][svcName] = 200
	return result

def healthcheck_to_bitbar(healthcheck):
	# Start the output to bitbar as the widget icon
	bitbar_out = widget_icon 
	for env, svcz_healthcheck in healthcheck.iteritems():
		# Detemine the saltiest http code in the svcz healthcheck
		saltiest_http_code = 200
		for status in svcz_healthcheck.itervalues():
			if status > saltiest_http_code:
				saltiest_http_code = status
		saltiest_color = bitbar_status_from_http_code(saltiest_http_code)

		bitbar_out += ";---;" +\
		"{} | font=32 color={};".format(env.capitalize(), saltiest_color)+\
		"{};".format(servicez_healthcheck_to_bitbar_status(svcz_healthcheck))
	return bitbar_out

def servicez_healthcheck_to_bitbar_status(svcz_healthcheck):
	bitbar_out = ""
	for svc, status in svcz_healthcheck.iteritems():
		bitbar_out += "--{} | color={};".format(svc, bitbar_status_from_http_code(status))
	return bitbar_out

def bitbar_status_from_http_code(http_code):
	if http_code > 399:
		return "red"
	if http_code > 299:
		return "yellow"
	if http_code > 199:
		return "green"

def bitbar_error(error_msg):
	print(error_msg)

if __name__ == '__main__':
    main()