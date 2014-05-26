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
            strSQL = "DELETE FROM deadlines WHERE id = " & reader.SelectSingleNode("/deadline/@id").InnerText
            '-- Open a database connection - OLEDB
            Dim DBConnection = New OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0; data source=" & Server.MapPath("timePlanner.accdb"))
            DBConnection.Open()
            '-- Create and issue an SQL command through the database connection
            Dim DBCommand = New OleDbCommand(strSQL, DBConnection)
            DBCommand.ExecuteNonQuery()
            DBConnection.Close()
    
            'response.write("SQL: " & strSQL)
    
            ' now refresh the data and return the XML in the response
            Response.Redirect("retrieveAdminData.aspx")
        End If
    End Sub

</script>
