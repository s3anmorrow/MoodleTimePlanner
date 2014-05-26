<%@ Page Language="vb" Debug="true" validaterequest="false" %>
<script runat="server">
    sub page_load()
        If (Session("login") Is Nothing) Then
            Response.Redirect("login.htm")
        ElseIf (Session("login") = false) Then
            Response.Redirect("login.htm")
        End If
    end sub
</script>

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>Student Timeplanner Admin</title>
        <link rel="stylesheet" type="text/css" href="resources/adminStyles.css" />
        <link type="text/css" href="resources/custom-theme/jquery-ui-1.8.17.custom.css" rel="Stylesheet" />	
        <script type="text/javascript" src="resources/responseTrace.js"></script>
        <script type="text/javascript" src="resources/jquery-1.7.1.min.js"></script>
        <script type="text/javascript" src="resources/jquery.blockUI.js"></script>
        <script type="text/javascript" src="resources/jquery-ui-1.8.17.custom.min.js"></script>
        <script type="text/javascript" src="resources/jquery.liveValidation.js"></script>

        <script type="text/javascript">
            // retrieve server sided script
            var retreiveScript = "scripts/retrieveAdminData.aspx";
            var editScript = "scripts/editData.aspx";
            var addScript = "scripts/addData.aspx";
            var delScript = "scripts/delData.aspx";
            // the xml returned by the XmlHttpRequest object (via JQuery AJAX)
            var xmlObject;
            var deadlineCount = 0;
            // timer to count down session expiration
            var expireTimer;
            var warningTimer;
            // time to warning/expiration in minutes
            var warningTime = 17;
            var expirationTime = 19.5;
            // variable to hold reference to popup window object
            var popWin;
            // currently selected deadline id
            var id = -1;
            // currently selected studentYear filter
            var yearFilter = -1;

            // ------------------------------------------------------- event handlers
            function onLoaded(result, textStatus, xmlhttp) {
                // grab the XML response
                xmlObject = result;
                deadlineCount = xmlObject.getElementsByTagName("deadline").length;
                populateMe(yearFilter);
                if (deadlineCount > 0) {
                    // adjust current selected deadline to be the last one before refresh (if applicable)
                    if (id == -1) {
                        // id has not been set yet or deletion has just occurred
                        id = xmlObject.getElementsByTagName("deadline")[0].getAttribute("id")
                    } else {
                        // set current deadline to id so that it doesn't reset back to the first listItem (on reload after edit, add, delete)
                        $("#lstDeadline option").each(function (index) {
                            if (id == $(this).prop("id")) {
                                $("#lstDeadline").prop("selectedIndex", index);
                                return false; // break loop
                            }
                        })
                    }
                    resetCountDown();
                    onChanged();
                }

                // show dropdowns now that data is ready
                $("#lstFilter").css("visibility", "visible");
                $("#lstDeadline").css("visibility", "visible");
                enableMe();
            }

            function onChanged() {
                // grab currently selected option
                var listItem = $("#lstDeadline option:selected");
                // save current id
                id = $(listItem).prop("id");
                // update divs below with the corresponding attribute values of the selected option
                $("#txtEditName").val($(listItem).prop("name"));
                $("#txtEditDescription").val($(listItem).prop("description"));
                $("#lstEditStudentType").val($(listItem).prop("studentYear"));
                $("#txtEditDate").val($(listItem).prop("dueMonth") + "-" + $(listItem).prop("dueDay"));

                // re-validate both forms now that I have populated them through code
                $("#addPane").liveValidation("validateNow");
                $("#editPane").liveValidation("validateNow");
                // check if button needs enabling or disabling
                onValidFormCheck();
            }

            function onValidFormCheck() {
                // assume that add pane and edit pane is invalid and test for otherwise
                $("#btnAdd").prop("disabled", true);
                $("#btnEdit").prop("disabled", true);
                if ($("#addPane").liveValidation("isValid")) $("#btnAdd").prop("disabled", false);
                if ($("#editPane").liveValidation("isValid")) $("#btnEdit").prop("disabled", false);
            }

            function onEdit() {
                // grab currently selected option
                var listItem = $("#lstDeadline option:selected");
                // construct XML snippet to send as a string
                var sendXML = "<deadline id='" + $(listItem).prop("id") + "'><name>" + $("#txtEditName").val() + "</name><year>" + $("#lstEditStudentType option:selected").val() + "</year><description>" + sanitize($("#txtEditDescription").val()) + "</description><duemonth>" + $("#txtEditDate").val().split("-")[0] + "</duemonth><dueday>" + $("#txtEditDate").val().split("-")[1] + "</dueday></deadline>";
                sendData(editScript, sendXML);
            }
 
            function onAdd() {
                // construct XML snippet to send as a string
                var sendXML = "<deadline><name>" + $("#txtAddName").val() + "</name><year>" + $("#lstAddStudentType option:selected").val() + "</year><description>" + sanitize($("#txtAddDescription").val()) + "</description><duemonth>" + $("#txtAddDate").val().split("-")[0] + "</duemonth><dueday>" + $("#txtAddDate").val().split("-")[1] + "</dueday></deadline>";

                // clear out add textboxes for next entry
                $("#addPane input[type='text']").val("");
                $("#addPane textarea").val("");
                sendData(addScript, sendXML);
            }

            function onDelete() {
                // reset current id since I am deleting current deadline
                id = -1;
                // construct XML snippet to send as a string
                var sendXML = "<deadline id='" + $("#lstDeadline option:selected").prop("id") + "'></deadline>";
                sendData(delScript, sendXML);
            }

            function onView() {
                popWin = window.open("timePlanner.htm", "timePlannerView", "toolbar=no,location=no,directories=no, status=no,menubar=no,titlebar=no,scrollbars=yes,resizable=no,dependent=no,alwaysRaised=yes,width=900,height=800,left=10,top=10");
                popWin.document.documentElement.style.overflow = 'hidden';  // firefox, chrome
                popWin.document.body.scroll = "no"; // ie only
                popWin.focus();
            }

            function onFilter() {
                yearFilter = $("#lstFilter").val();
                populateMe(yearFilter);
                onChanged();
            }

            function onError(xmlhttp, textStatus) {
                responseTrace(xmlhttp);
            }

            // ------------------------------------------------------- private methods
            function disableMe() {
                // disabling the entire RIA using loading overlay
                $("#loadingOverlay").show();
            }

            function enableMe() {
                // fade out loading overlay
                $("#loadingOverlay").delay(300).fadeOut(300);
            }

            function resetCountDown() {
                // clear out existing timers if exist
                clearTimeout(expireTimer);
                clearTimeout(warningTimer);
                // setup timeout that will fire when session has expired (20 minutes = 60000 * 20 milliseconds)
                expireTimer = setTimeout(function () {
                    // session has expired!
                    document.location = "login.htm";
                }, (expirationTime * 60 * 1000));
                // setup timeout that will fire when the session is 2 minutes from expiring to warn user
                warningTimer = setTimeout(function () {
                    $("#warningOverlay").show();

                }, (warningTime * 60 * 1000));                
            }

            function sanitize(input) {
                // clean dodgy characters
                input = input.replace(/&/g, "&amp;");
                input = input.replace(/</g, "&lt;");
                input = input.replace(/>/g, "&gt;");
                input = input.replace(/"/g, "&quot;");
                return input;
            }

            function sendData(script, sendXML) {
                //console.log("sendXML: " + sendXML);
                disableMe();
                // send request via AJAX along with XML snippet
                $.ajax({
                    type: "POST", url: script, contentType: "text/xml", data: sendXML, dataType: "xml", success: onLoaded, error: onError
                });
            }

            function getData() {
                disableMe();
                // send out ajax request to get initial data
                $.ajax({
                    url: retreiveScript + "?tricky=" + Math.random(), datatype: "xml", success: onLoaded, error: onError
                });
            }

            function populateMe(targetYear) {
                // clear out dropdown
                $("#lstDeadline").text("");

                // populate the dropdown menu
                for (var i = 0; i < deadlineCount; i++) {
                    // create option element for dropdown (listItem) if match student type selected in filter
                    var currentYear = xmlObject.getElementsByTagName("year")[i].childNodes[0].nodeValue;
                    if ((currentYear == targetYear) || (targetYear == -1)) {
                        var option = document.createElement("option");
                        option.text = xmlObject.getElementsByTagName("name")[i].childNodes[0].nodeValue;
                        option.id = xmlObject.getElementsByTagName("deadline")[i].getAttribute("id");
                        option.name = option.text;
                        option.author = xmlObject.getElementsByTagName("author")[i].childNodes[0].nodeValue;
                        option.authorName = xmlObject.getElementsByTagName("authorname")[i].childNodes[0].nodeValue;
                        option.studentYear = currentYear;
                        option.description = xmlObject.getElementsByTagName("description")[i].childNodes[0].nodeValue;
                        option.dueMonth = xmlObject.getElementsByTagName("duemonth")[i].childNodes[0].nodeValue;
                        option.dueDay = xmlObject.getElementsByTagName("dueday")[i].childNodes[0].nodeValue;

                        // add element to lstDeadline as a new option
                        $("#lstDeadline").append(option);
                    }
                }
                // disabling deadline dropdown and accordion panels if drop down empty (no deadlines)
                if ($("#lstDeadline option").size() == 0) {
                    $("#lstDeadline").prop("disabled", true);
                    $("#editPane table").css("visibility", "hidden");
                    $("#editPane div").show();
                    $("#delPane div:eq(1)").css("visibility", "hidden");
                    $("#delPane div:eq(0)").show();
                } else {
                    $("#lstDeadline").prop("disabled", false);
                    $("#editPane table").css("visibility", "visible");
                    $("#editPane div").hide();
                    $("#delPane div:eq(1)").css("visibility", "visible");
                    $("#delPane div:eq(0)").hide();
                }
            }

            // ------------------------------------------------------- JQuery Implementation
            $(document).ready(function () {
                // setup accordian : part of JQuery UI plugin framework
                $("#accordion").accordion({ autoHeight: false });

                // setup live validation - using the Live Validation JQuery plugin
                $("#addPane").liveValidation({
                    validIco: "resources/valid.png",
                    invalidIco: "resources/invalid.png",
                    required: ["txtAddName", "txtAddDate"],
                    fields: { txtAddName: /^(\w|\s|\'|\?|\.|\!|:|-)+$/, txtAddDate: /^(\d|\d\d)\-(\d|\d\d)$/ }
                });
                $("#editPane").liveValidation({
                    validIco: "resources/valid.png",
                    invalidIco: "resources/invalid.png",
                    required: ["txtEditName", "txtEditDate"],
                    fields: { txtEditName: /^(\w|\s|\'|\?|\.|\!|:|-)+$/, txtEditDate: /^(\d|\d\d)\-(\d|\d\d)$/ }
                });

                // setup datepickers - set it to trigger a keyup event when selected so that the liveValidator does validation
                $("#txtEditDate").datepicker({
                    dateFormat: "mm-dd",
                    onSelect: function () {
                        $("#txtEditDate").trigger("keyup");
                        $("#txtEditDate").blur();
                    },
                    onclose: onValidFormCheck
                });
                $("#txtAddDate").datepicker({
                    dateFormat: "mm-dd",
                    onSelect: function () {
                        $("#txtAddDate").trigger("keyup");
                        $("#txtAddDate").blur();
                    },
                    onclose: onValidFormCheck
                });

                // setup event handlers
                $("#lstDeadline").change(onChanged);
                $("#lstFilter").change(onFilter);
                $("#btnEdit").click(onEdit);
                $("#btnAdd").click(onAdd);
                $("#btnDelete").click(onDelete);
                $("#addPane").keyup(onValidFormCheck);
                $("#editPane").keyup(onValidFormCheck);
                $("a:contains('View Timeplanner')").click(onView);
                $("#warningOverlay a").click(function () { $("#warningOverlay").fadeOut(300); getData(); });

                getData();
            });

        </script>
    </head>
    <body>
        <div>
            <div class="headerPane">
                <img src="resources/titleAdmin.png" alt="Student Timeplanner Administration" />
            </div>

            <div class="menuPane">
                <select id="lstDeadline" style="visibility:hidden"></select>
                <span style="float:right">
                    Filter Deadlines:
                    <select id="lstFilter" style="visibility:hidden">
                        <option value="-1" selected="selected">All Deadlines</option>
                        <option value="1">IT 1st Year</option>
                        <option value="2">IT 2nd Year Web</option>
                        <option value="3">IMOG 1st Year</option>
                        <option value="4">IMOG 2nd Year Game</option>
                        <option value="0">General Posting</option>
                    </select>
                </span>
                <br /><br />
                Select the task you wish to carry out and fill in the appropriate information into the form...
            </div>

            <div id="accordion" class="accordianPane">
                <h3><a href="#">Edit</a></h3>
                <div id="editPane">
                    <div style="display:none">Not available...</div>
                    <table>
                        <tr><td style="text-align:right">Deadline Name:</td><td><input id="txtEditName" type="text" size="45" maxlength="50" /></td></tr>
                        <tr><td style="text-align:right">Deadline Description:</td><td><textarea id="txtEditDescription" cols="70" rows="18"></textarea></td></tr>
                        <tr><td style="text-align:right">Student Type:</td><td><select id="lstEditStudentType"><option value="1">IT 1st Year</option><option value="2" selected="selected">IT 2nd Year Web</option><option value="3">IMOG 1st Year</option><option value="4">IMOG 2nd Year Game</option><option value="0">General Posting</option></select><input id="actualEditDate" type="hidden" /></td></tr>
                        <tr><td style="text-align:right">Deadline Date (MM-DD):</td><td><input id="txtEditDate" type="text" size="20" maxlength="30" /></td></tr>
                        <tr><td>&nbsp;</td><td><input id="btnEdit" type="button" value="Ok" /><a href="#" style="float:right;">View Timeplanner</a></td></tr>
                    </table>
                </div>

                <h3><a href="#">Add</a></h3>
                <div id="addPane">
                    <table>
                        <tr><td style="text-align:right">Deadline Name:</td><td><input id="txtAddName" type="text" size="45" maxlength="50" /></td></tr>
                        <tr><td style="text-align:right">Deadline Description:</td><td><textarea id="txtAddDescription" cols="70" rows="18"></textarea></td></tr>
                        <tr><td style="text-align:right">Student Type:</td><td><select id="lstAddStudentType"><option value="1">IT 1st Year</option><option value="2" selected="selected">IT 2nd Year Web</option><option value="3">IMOG 1st Year</option><option value="4">IMOG 2nd Year Game</option><option value="0">General Posting</option></select></td></tr>
                        <tr><td style="text-align:right">Deadline Date (MM-DD):</td><td><input id="txtAddDate" type="text" size="20" maxlength="30" /></td></tr>
                        <tr><td>&nbsp;</td><td><input id="btnAdd" type="button" value="Ok" /><a href="#" style="float:right;">View Timeplanner</a></td></tr>
                    </table>
                </div>

                <h3><a href="#">Delete</a></h3>
                <div id="delPane">
                    <div style="display:none">Not available...</div>
                    <div style="width:500px;font-size:10px;">
                        Delete deadline? <input id="btnDelete" type="button" value="Ok" style="margin-left:3px;" /><a href="#" style="float:right;">View Timeplanner</a>
                    </div>
                </div>
            </div>

            <div id="errorPane"></div>

	        <div id="loadingOverlay" class="overlay">
		        <div style="position:absolute;left:250px;top:200px;"><img src="resources/loadingAdmin.gif" style="vertical-align:middle" alt="Loading" /> Loading Data...Please wait :)</div>
	        </div>	

            <div id="warningOverlay" class="overlay" style="display:none">
		        <div style="position:absolute;left:200px;top:200px;">WARNING : Session is about to expire. <a href="#">Click here to refresh</a> :)</div>
	        </div>

        </div>
    </body>
</html>