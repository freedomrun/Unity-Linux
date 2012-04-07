<?php

$current_tabs = array();

function add_tab($name, $content)
{
	global $current_tabs;
	$current_tabs[] = array('name' => $name, 'content' => $content);
}

function display_tabs($width = '50%')
{
	global $current_tabs;

	print_css_for_tabs($width);
	print_javascript_for_tabs();

	print "<div id='tabs-ex'>\n";
	print "  <ul class='tablist' id='tablist-mydisplay'>\n";

	$i = 0;
	foreach ($current_tabs as $instance => $details) {
		print "    <li rel='tab$i'>";
		print $details['name'];
		print "    </li>\n";
		$i++;
	}
	print "  </ul>\n\n";

	$i = 0;
	foreach ($current_tabs as $instance => $details) {
		print "  <div class='tab' id='tab$i'>\n";
		print "    <form action='' method='post'>\n";
		print "      <fieldset>\n";
		print $details['content'];
		print "      </fieldset>\n";
		print "    </form>\n";
		print "  </div>\n\n";
		$i++;
	}

	print "</div>\n";
}

function print_css_for_tabs($width)
{
	echo <<<ENDCSS
<style type="text/css">
	#tabs-ex {
	font-family: Arial, Helvetica, sans-serif;
	width: $width;
	margin: 1em auto;
	}
	#tabs-ex ul.tablist {
	list-style: none inside;
	margin: 0;
	padding: 0;
	}
	#tabs-ex ul.tablist li {
	display: block;
	float: left;
	background: #ddd;
	border-top: 1px solid #ddd;
	border-bottom: 1px solid black;
	position: relative;
	bottom: -1px;
	padding: 0.5em;
	margin-right: 2px;
	cursor: pointer;
	}
	#tabs-ex ul.tablist li.tab_hi {
	background: white;
	border-left: 1px solid black;
	border-right: 1px solid black;
	border-top: 1px solid black;
	border-bottom: 1px solid white;
	}
	#tabs-ex div.tab {
	border: 1px solid black;
	clear: both;
	padding: 0.5em;
	background: white;
	}
	div.tab form {
	margin: 0 1em 0;
	}

	div.tab form fieldset {
	border: 0px solid black;
	}

	div.tab form legend {
	display: none;
	}

	div.tab form label {
	display: block;
	position: relative;
	line-height: 1.5em;
	margin-bottom: 0.5em;
	}

	div.tab form label.bad {
	color: red;
	}

	div.tab form input.submit {
	margin: 1em auto;
	display: block;
	}

	div.tab form label input {
	position: absolute;
	right: 0;
	width: 60%;
	}

	#tabs-ex p {
	padding-top: 1em;
	text-align: center;
	}
</style>
ENDCSS;
}

function print_javascript_for_tabs()
{
	echo <<<ENDJS
<script type="text/javascript">
	tabMagic = {
	_map: {},

	init: function()
	{
		l = document.getElementsByTagName('ul');
		for(i=0; i<l.length; i++)
		{
		if(l[i].className.indexOf('tablist') >= 0)
		{
		t = l[i].getElementsByTagName('li');
		for(j=0; j<t.length; j++)
		{
		tabMagic._map[t[j].getAttribute('rel')] = l[i].id;
		t[j].onclick = function()
		{
			tabMagic.sw(this.getAttribute('rel'));
			return false;
		};
		}
		tabMagic.sw(t[0].getAttribute('rel'));
		}
		}
	},

	sw: function(tr)
	{
		tl = document.getElementsByTagName('ul');
		for(li=0; li<tl.length; li++)
		{
		if(tl[li].className.indexOf('tablist') >= 0 && tl[li].id == tabMagic._map[tr])
		{
			items = tl[li].getElementsByTagName('li');
		for(lj=0; lj<items.length; lj++)
		{
		if(items[lj].getAttribute('rel') == tr)
		{
			items[lj].className = 'tab_hi';
			document.getElementById(items[lj].getAttribute('rel')).style.display = 'block';
		}
		else
		{
			items[lj].className = 'tab';
			document.getElementById(items[lj].getAttribute('rel')).style.display = 'none';
		}
		}
		}
		}
	}
	};

	window.onload = tabMagic.init;
</script>
ENDJS;
}

?>
