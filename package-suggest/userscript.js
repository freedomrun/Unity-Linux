/* Anurag Bhandari
 * 23-07-09
 *
 * This JavaScript code tries to bridge the wiki-based package suggest system with the bug tracker.
 * Discussion on this was held at: http://issues.unity-linux.org/index.php?do=details&task_id=66
 * Powered by jQuery.
 *
 */

$(document).ready(function() {
  /* Remove the attributes 'method' and 'action' from the form; this is because we'll be using AJAX for submitting the form. */
  $('#bureaucracy__plugin').removeAttr("method");
  $('#bureaucracy__plugin').removeAttr("action");

  /* Add a hidden loader animated gif below the form. */
  $('#bureaucracy__plugin').append('<center><image id="loader" style="display:none; margin:10px 0 10px 0;" src="/lib/images/loader.gif"/></center>');
  
  /* Do this when the submit button of the form is pressed. */
  $('#bureaucracy__plugin').submit(function() {
    $('#loader').show();
    // Check if all the fields have been filled in
    if($('#bureaucracy1').val()!='' && $('#bureaucracy2').val()!='' && $('#bureaucracy3').val()!='' && $('#bureaucracy4').val()!='' && $('#bureaucracy5').val()!='' && $('#bureaucracy7').val()!='' && $('#bureaucracy8').val()!='' && $('#bureaucracy10').val()=='orange')
    {
      // Irrespective of whether what is submitted already exists or not, following will execute.
      // But it's quite safe as no changes are made to an already existing submission.
      $.post("/doku.php/packages:submit", { sectok: $('input[name=sectok]').val(), id: $('input[name=id]').val(), 'bureaucracy[]': ["", $('#bureaucracy1').val(), $('#bureaucracy2').val(), $('#bureaucracy3').val(), $('#bureaucracy4').val(), $('#bureaucracy5').val(), "", $('#bureaucracy7').val(), $('#bureaucracy8').val(), "", $('#bureaucracy10').val()] }, function(data) { $('#bureaucracy__plugin').append('<center><div style="font-weight:bold; color:green; margin:10px 0 10px 0;">Package page at wiki: <a href="/doku.php/packages:' + $('#bureaucracy1').val() + '">' + $('#bureaucracy1').val() + '</a>.</div></center>'); $('#loader').hide(); });

      // If what is submitted already exists, this will show error message. Else, it is submitted to the db.
      $.post("/lib/scripts/addToFlySpray.php", { 'bureaucracy[]': ["", $('#bureaucracy1').val(), $('#bureaucracy2').val(), $('#bureaucracy3').val(), $('#bureaucracy4').val(), $('#bureaucracy5').val(), "", $('#bureaucracy7').val(), $('#bureaucracy8').val(), "", $('#bureaucracy10').val()] }, function(data) { $('#bureaucracy__plugin').append(data); });
    }
    // If all the fields were not filled in, give an error
    else {
      alert("You have to fill in all the fields in the form. Also make sure the spambot protection field was filled in correctly."); $('#loader').hide();
    }
    return false;
  });
});