# Create cross-browser CORS-compatible `XMLHTTPRequest`
#
# @param [String] method HTTP method
# @param [String] url Request URL
# @return [XMLHttpRequest|XDomainRequest]
# @see http://www.html5rocks.com/en/tutorials/cors/
# @throw CORS-supported XHR object could not be created
#
getXHR = (method, url) ->
	supported = false

	xhr = new XMLHttpRequest()

	if "withCredentials" of xhr
		xhr.open(method, url, true)

	else if typeof XDomainRequest != "undefined"
		xhr = new XDomainRequest()
		xhr.open(method, url)

	else
		throw new Error "CORS-supported XHR object could not be created"

	return xhr


# Wrap callback to handle JSON response to `load`
#
# @param [Function] callback
# @return [Function]
#
wrapCallback = (callback) ->
	return (e) ->
		callback(decodeJSON(event.target.responseText))


# Deep copy the contents of an arbitrary object
#
# @param [Object] source
# @return [Object]
#
deepCopy = (source) ->
	if typeof source == "object"
		if not source?
			return null
		else if source instanceof Array
			copy = []
			for val, i in source
				copy[i] = deepCopy(source[i])
		else if source instanceof Object
			copy = {}
			for prop of source
				copy[prop] = deepCopy(source[prop])
	else
		return source

	return copy


# Decode JSON
#
# @param [String] body
# @return [Object]
#
decodeJSON = (body) ->
	try
		content = JSON.parse(body)
	catch
		throw new Error "Malformed response"

	if content.error?
		throw new Error "API call failed: #{content.error}"

	return content


# Resume Funnel Embed
#
# @see https://github.com/resumefunnel/embed
#
class Embed

	# @property [String] API URL
	#
	@ROOT: "https://api.resumefunnel.com/1"
	
	# @property [Number] Account ID
	#
	accountId: 0

	# @property [String] Account API key
	#
	accountApiKey: ""

	
	# Initiate
	#
	# @param [String] accountId Account ID
	# @param [String] accountApiKey Account API key
	# @param [Object] options
	#
	constructor: (@accountId, @accountApiKey) ->
		Embed.checkDependencies()
		Embed.checkBrowser()


	# Check options are valid types
	# 
	# @param [Object] options
	# @throws `template` option must be a string
	# @throws `success` option must be a function
	# @throws `error` option must be a function
	#
	@checkOptions: (options) ->
		if options.template?
			if not "charAt" of options.template
				throw new Error "`template` option must be a string"

		if options.success?
			if typeof options.success isnt "function"
				throw new Error "`success` option must be a function"

		if options.error?
			if typeof options.error isnt "function"
				throw new Error "`error` option must be a function"

	
	# Check browser is supported
	#
	# @throw CORS-supported XHR object could not be created
	#
	@checkBrowser: () ->
		getXHR()

		if not FormData?
			throw new Error "Your Web browser does not support the FormData interface"
	
	
	# Check dependencies are loaded
	#
	# @throw CORS-supported XHR object could not be created
	#
	@checkDependencies: () ->
		if typeof Mustache == "undefined"
			throw new Error "Embed depends on Mustache: https://github.com/janl/mustache.js"

	
	# Make a POST API request
	#
	# @param [String] path
	# @param [Object] data
	# @param [Function] callback
	# 
	post: (path, data, callback) =>
		request = getXHR("POST", "#{Embed.ROOT}/#{@accountId}#{path}")
		request.setRequestHeader("Accept", "application/json")
		request.setRequestHeader("Authorization", "Bearer #{@accountApiKey}")
		request.addEventListener("load", wrapCallback(callback))
		request.send(data)
	
	
	# Make a GET API request
	#
	# @param [String] path
	# @param [Function] callback
	# 
	get: (path, callback) =>
		request = getXHR("GET", "#{Embed.ROOT}/#{@accountId}#{path}")
		request.setRequestHeader("Accept", "application/json")
		request.setRequestHeader("Authorization", "Bearer #{@accountApiKey}")
		request.addEventListener("load", wrapCallback(callback))
		request.send()

	
	# Get all jobs
	#
	# @param [Function] callback
	#
	getJobs: (callback=()->{}) =>
		@get("/jobs", (jobs) => callback(new JobList(@, jobs)))

	
	# Get job
	#
	# @param [Number] id Job ID
	# @param [Function] callback
	#
	getJob: (id, callback=()->{}) =>
		@get("/jobs/#{id}/embed", (job) => callback(new Job(@, job)))


# Job
#
class Job
	# @property [Object] Job data
	#
	# Retrieved asynchronously from Resume Funnel
	#
	data: {}
	
	# @property [Number] Job ID
	#
	id: 0
	

	# Initiate
	#
	constructor: (@embed, @data) ->
		@id = @data.job.id


	# Submit candidate application
	#
	# @param [FormData] data Candidate application
	# @param [Function] callback
	#
	apply: (data, callback) =>
		@embed.post("/jobs/#{@id}/candidates", data, wrapCallback(callback))
	

	# Populate element
	#
	# @property [Element] element The container element
	# @property [Object] options
	# @return [JobManager]
	#
	populate: (element, options={}) ->
		new JobManager(@, element, options)


# Job list
#
class JobList
	
	# @property [Object] Job list data
	#
	# Retrieved asynchronoously from Resume Funnel
	#
	data: {}
	
	
	# Initiate
	#
	constructor: (@embed, @data) ->


	# Populate element
	#
	# @property [Element] element The container element
	# @property [Object] options
	# @return [JobListManager]
	#
	populate: (element, options={}) ->
		new JobListManager(@, element, options)


# Job list manager
#
class JobListManager

	# @property [Element] A container in which to render the job application
	#
	element: null
	
	# @property [Object] Options
	#
	options: {}

	# @property [String] A Mustache-based job application template
	# @see https://github.com/janl/mustache.js
	#
	template: """<form class="openings">""" +
			"""<div class="title"><h1>Current Openings</h1></div>""" +
			"""<div class="jobs">{{#jobs}}""" +
				"""<div class="job">""" +
					"""<a href="#">{{title}}</a>""" +
				"""</div>""" +
			"""{{/jobs}}</div>""" +
		  """</form>"""


	# Initiate
	#
	constructor: (@jobList, @element, @options={}) ->
		# If user-created template provided, use that instead of default
		if @options.template?
			@template = @options.template

		# If using jQuery, unwrap the element
		if typeof @element.jquery != "undefined"
			@element = @element[0]

		@render()


	# Render loaded jobs
	#
	render: () =>
		content = Mustache.render(@template, @jobList.data)
		@_setContent(content)


	# Set content for element container
	#
	# @param [String] HTML content for container
	#
	_setContent: (content) =>
		@element.innerHTML = content


# Job manager
#
class JobManager

	# @property [Element] A container in which to render the job application
	#
	element: null

	# @property [HTMLFormElement] The container's `form` element
	#
	formElement: null
	
	# @property [Object] Options
	#
	options: {}

	# @property [String] A Mustache-based job application template
	# @see https://github.com/janl/mustache.js
	#
	template: """<form class="application" action="{{form.action}}" method="{{form.method}}" enctype="{{form.enctype}}">""" +
			"""{{#job}}<div class="title"><h1>Apply for {{title}}</h1></div>""" +
			"""<div class="questions">{{#questions}}""" +
				"""<div class="question">""" +
					"""<label for="question-{{id}}">{{question}}</label>""" +
					"""{{#is_input}}""" +
						"""<input type="{{kind}}" id="question-{{id}}" name="{{name}}" />""" +
					"""{{/is_input}}""" +
					"""{{#is_textarea}}""" +
						"""<textarea id="question-{{id}}" name="question_{{id}}"></textarea>""" +
					"""{{/is_textarea}}""" +
					"""<div class="help">{{help}}</div>""" +
					"""<div class="errors">{{#errors}}{{message}}<br />{{/errors}}</div>""" +
				"""</div>""" +
			"""{{/questions}}</div>{{/job}}""" +
			"""<input type="submit" value="Submit application" />""" +
		  """</form>"""


	# Initiate
	#
	constructor: (@job, @element, @options={}) ->
		# If user-created template provided, use that instead of default
		if @options.template?
			@template = @options.template

		# If using jQuery, unwrap the element
		if typeof @element.jquery != "undefined"
			@element = @element[0]

		@render()


	# Handle job submission response
	#
	# @param [Object] data
	#
	_callback: (data) =>
		job_data = deepCopy(@job.data)

		# Add workaround logic for logicless templating
		job_data.is_submitted = true
		job_data.is_success = data.success
		job_data.is_error = !data.success

		for question in job_data.job.questions
			question.is_textarea = question.kind == "textarea"
			question.is_input = question.kind != "textarea"

		# Invoke callbacks
		if data.success
			 @options.success?()
		else
			 @options.error?()

		# Inject errors into job application data
		for question in job_data.job.questions
			question.errors = if data.errors[question.name] then data.errors[question.name] else []

		content = Mustache.render(@template, job_data)
		@_setContent(content)
		@_bind()


	# Render loaded job application
	#
	render: () =>
		# Add workaround logic for logicless templating
		job_data = deepCopy(@job.data)
		job_data.is_submitted = false

		for question in job_data.job.questions
			question.is_textarea = question.kind == "textarea"
			question.is_input = question.kind != "textarea"

		content = Mustache.render(@template, job_data)
		@_setContent(content)


	# Reset all form values
	#
	reset: () =>
		for input in @formElement.getElementsByTagName("input")
			input.value = ""
		for textarea in @formElement.getElementsByTagName("input")
			textarea.value = ""


	# Set content for element container
	#
	# @param [String] HTML content for container
	#
	_setContent: (content) =>
		@element.innerHTML = content

		# Find `form` element
		forms = @element.getElementsByTagName("form")

		if forms.length == 0
			throw new "Application template must contain a `<form>` element"
		else if forms.length > 1
			throw new "Application template must contain only one `<form>` element"

		@formElement = forms[0]
		@_bind()


	# Bind `submit` events for submission
	#
	_bind: () =>
		@formElement.addEventListener("submit", @submit)


	# Unbind `submit` events for submission
	#
	_unbind: () =>
		@formElement.removeEventListener("submit", @submit)


	# Submit candidate application
	# 
	# @param [Event] event
	#
	submit: (event) =>
		event.preventDefault()
		@_unbind()

		data = new FormData(@formElement)
		@job.apply(data, @_callback)

	
window.ResumeFunnel ?= {}
window.ResumeFunnel.Embed = Embed
