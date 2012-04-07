<?php

function print_debug($msg)
{
	global $debug;

	if ($debug) {
		$formated_msg = str_replace("\n", "<br/>", $msg);
		$formated_msg = str_replace(" ", "&nbsp;", $formated_msg);
		print "DEBUG: $formated_msg<p/>\n";
	}
}

function dump($var)
{
	ob_start();
	print_r($var);
	$dump = ob_get_clean();
	print_debug($dump);
}

?>
