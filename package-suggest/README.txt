Introduction
------------
These are a set of scripts that are intended to bridge the DokuWiki package suggestion form with the FlySpray issue tracker of Unity. Using these, one can implement the feature of automatically adding a package suggestion as a task, into the issue tracker, when the package suggestion form is submitted at the DokuWiki form: http://docs.unity-linux.org/doku.php/packages:submit.


How does it work?
-----------------
When a user clicks on the submit button in the form (http://docs.unity-linux.org/doku.php/packages:submit), an AJAX request is sent to submit the package suggestion to two locations: dokuwiki and flyspray database. The PHP handler script checks if a package with the same name already exists. If it does, an error is shown for the same to the user; if it doesn't, the package suggestion is submitted and corresponding success messages are displayed to the user. Further, my JavaScript code makes sure that all of the fields are filled in and that the spambot protection field is filled in correctly. Otherwise, an alert message pops up asking the user to fill the form properly. All this happens within a very short time (thanks to AJAX).


FILE				LOCATION ON SERVER
----				------------------
addToFlySpray.php*		public_html/docs/lib/scripts
jquery-1.3.2.min.js^		public_html/docs/lib/scripts
js.php				public_html/docs/lib/exe
loader.gif			public_html/docs/lib/images
syntax.php			public_html/docs/lib/plugins/bureaucracy
userscript.js*			public_html/docs/conf

* = I wrote these scripts
^ = external files needed for everything to work properly
All other files are hacked files from DokuWiki installation.