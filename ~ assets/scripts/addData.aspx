<%@ Page Language="vb" Debug="true" validaterequest="false" %>
<%@ import Namespace="System.Data.OleDb" %>
<%@ import Namespace="System.Xml" %>

<script runat="server">

    Sub Page_Load
        If (Session("login")) Then
            ' use XPath to parse XML
            Dim reader As XmlDocument = New XmlDocument()
            reader.Load(Request.InputStream)

            '-- constucting UPDATE sql
            Dim strSQL As String
            strSQL = "INSERT INTO deadlines (author,name,description,dueMonth,dueDay,studentYear) VALUES " & _
            "(@author,@name,@description,@dueMonth,@dueDay,@studentYear)"

            '-- Open a database connection - OLEDB
            Dim DBConnection = New OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0; data source=" & Server.MapPath("timePlanner.accdb"))
            DBConnection.Open()
            '-- Create and issue an SQL command through the database connection
            Dim DBCommand = New OleDbCommand(strSQL, DBConnection)
				
            ' parameterized queries
            DBCommand.Parameters.AddWithValue("@author", Session("user"))
            DBCommand.Parameters.AddWithValue("@name", reader.SelectSingleNode("/deadline/name[1]").InnerText)
			dim description as String = Server.htmlDecode(reader.SelectSingleNode("/deadline/description[1]").InnerText)
            DBCommand.Parameters.AddWithValue("@description", Server.HtmlEncode(description))
            DBCommand.Parameters.AddWithValue("@dueMonth", reader.SelectSingleNode("/deadline/duemonth[1]").InnerText)
            DBCommand.Parameters.AddWithValue("@dueDay", reader.SelectSingleNode("/deadline/dueday[1]").InnerText)
            DBCommand.Parameters.AddWithValue("@studentYear", reader.SelectSingleNode("/deadline/year[1]").InnerText)
				
            DBCommand.ExecuteNonQuery()
            DBConnection.Close()

            'response.write("SQL: " & strSQL)

            ' now refresh the data and return the XML in the response
            Response.Redirect("retrieveAdminData.aspx")
        End If
    End Sub

</script>
