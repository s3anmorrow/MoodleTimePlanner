<%@ Page Language="vb" Debug="true" %>
<%@ import Namespace="System.Data.OleDb" %>
<%@ import Namespace="System.Xml" %>

<script runat="server">

    Sub Page_Load()
        Dim userName As String
        Dim password As String
        
        '-- Open a database connection - OLEDB
        Dim DBConnection = New OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0; data source=" & Server.MapPath("timePlanner.accdb"))
        DBConnection.Open()
        
        ' parsing incoming XML
        Dim xmlDocReader As XmlDocument = New XmlDocument()
        xmlDocReader.Load(Request.InputStream)
        userName = xmlDocReader.SelectSingleNode("/request/user[1]").InnerText
        password = xmlDocReader.SelectSingleNode("/request/pass[1]").InnerText
        
        '-- Create and issue an SQL command through the database connection
        Dim DBCommand = New OleDbCommand("SELECT * FROM login WHERE username=@username", DBConnection)
        DBCommand.Parameters.AddWithValue("@username", userName)

        '-- Create a recordset of selected records from the database
        Dim reader = DBCommand.ExecuteReader()
        
        '-- instantiate XML document
        Dim xmlDocWriter As XmlTextWriter = New XmlTextWriter(Response.OutputStream, Nothing)
        '-- this line causes the XmlTextWriter to indent all child nodes (more readable by humans)
        xmlDocWriter.Formatting = Formatting.Indented
        Response.ContentType = "text/xml"
        xmlDocWriter.WriteStartDocument()
        '-- add XML root element
        xmlDocWriter.WriteStartElement("response")

        If (reader.Read()) Then
            '-- login ok - check password
            If (password = reader.Item("password")) Then
                '-- access granted
                '-- set up session variable to mark user has logged in successfully
                Session("login") = True
                Session("user") = userName
                '-- returning data to client side
                xmlDocWriter.WriteStartElement("access")
                xmlDocWriter.WriteString("true")
                xmlDocWriter.WriteEndElement()
            Else
                '-- access failed
                xmlDocWriter.WriteStartElement("access")
                xmlDocWriter.WriteString("false")
                xmlDocWriter.WriteEndElement()
            End If
        Else
            '-- access failed
            xmlDocWriter.WriteStartElement("access")
            xmlDocWriter.WriteString("false")
            xmlDocWriter.WriteEndElement()
        End If

        '-- close XML root
        xmlDocWriter.WriteEndElement()
        xmlDocWriter.WriteEndDocument()
        xmlDocWriter.Close()
        reader.Close()
        DBConnection.Close()

    End Sub

</script>
