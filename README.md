# Embed for Resume Funnel

Embed allows you to quickly add your company's jobs and job applications hosted on [Resume Funnel](https://www.resumefunnel.com) to your website.


## Install

### Direct download

[Download the latest release.](https://github.com/resumefunnel/embed/releases)

### As a dependency

You can also install Embed using your preferred package manager:

#### npm

	$ npm install resumefunnel-embed --save

#### Bower

	$ bower install resumefunnel-embed --save


## Prerequisities

You need an active <a href="https://www.resumefunnel.com">Resume Funnel</a> account with one or more published jobs. For security purposes, you must specify the domain names from which you will use Embed in your account's Settings page.


## Example

Check out [`demo/index.html`](demo/index.html) for a working example.

	<html>
		<body>
			<h1>Apply for this position!</h1>

			<!-- Here's an empty element that we will specify later to be used as the job application's container -->
			<div id="application-form"></div>

			<!-- Load Mustache.js -->
			<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/mustache.js/2.2.1/mustache.js"></script>

			<!-- Load Resume Funnel's Embed code -->
			<script src="/some/path/to/embed.js"></script>

			<script>
				// Initiate Embed with the your account ID and API key
				var embed = new ResumeFunnel.Embed(1, "HLikZyDF98JhfTnPIEVmcCJkDex9RY1E");
				// Load and render a job application with the job ID (#1) and DOM element
				embed.getJob(1, function(job){
					job.populate(document.getElementById("application-form"));
				});
			</script>
		</body>
	</html>


## Usage

`Embed` initiates the module for your account. `getJobs` fetches all published job posting and `Jobs.populate` renders them. Likewise, `getJob(id)` loads your job application, and `Job.populate` renders the necessary HTML, validates user input, and submits completed applications to your account.

### Options

You can specify additional options (e.g., `template`):

	job.populate(document.getElementById("application-form"), {
		'template': '<form action="{{form.action}}" method="post">
		                 {{#questions}}
		                     {{label_html}}
		                     {{input_html}}
		                     <div class="hint">{{hint}}</a>
		                 {{/questions}}
				 <input type="submit" value="Get this job!" />
		             </form>'
		},
	});

It's recommended to look at the included templates in the source code before you begin customizing your own.


### Callbacks

You can set the `success` or `error` option callbacks to customize your job application's behavior on a succcessful or failed application submission, respectively.


## Debugging

While implementing and customizing Embed, check your web browser's console for helpful error messages.


## Issues

Please add issues to [this project's GitHub issues](https://github.com/resumefunnel/embed/issues). For security-related inquiries, please contact Resume Funnel support at [support@resumefunnel.com](mailto:support@resumefunnel.com).


## License

BSD 3-clause License
