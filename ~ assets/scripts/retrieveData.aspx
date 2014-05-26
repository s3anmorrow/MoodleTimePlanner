<%@ Page Language="vb" Debug="true" %>
<%@ import Namespace="System.Data.OleDb" %>
<%@ import Namespace="System.Xml" %>
<script runat="server">

    Sub Page_Load

        '-- Open a database connection - OLEDB
        Dim DBConnection = New OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0; data source=" & Server.MapPath("timePlanner.accdb"))
        DBConnection.Open()
        '-- Create and issue an SQL command through the database connection
        Dim DBCommand = New OleDbCommand("SELECT deadlines.*, login.fullName FROM deadlines INNER JOIN login ON deadlines.author=login.username", DBConnection)

        '-- Create a recordset of selected records from the database
        Dim reader = DBCommand.ExecuteReader()

        '-- instantiate XML document
        '-- first parameter is where is this written to (could be an xml filename, but in this case we are streaming)
        '-- second parameter is encoding if any
        Dim xmlDoc As XmlTextWriter = New XmlTextWriter(Response.OutputStream, Nothing)
        '-- this line causes the XmlTextWriter to indent all child nodes (more readable by humans)
        xmlDoc.Formatting = Formatting.Indented
        Response.ContentType = "text/xml"
        xmlDoc.WriteStartDocument()

        '-- add XML root element
        xmlDoc.WriteStartElement("deadlines")

        Dim firstOne = True
        '-- for each record returned by query build student node of XML
        While reader.Read()
            xmlDoc.WriteStartElement("deadline")
            xmlDoc.WriteAttributeString("id",reader.Item("id"))

            xmlDoc.WriteStartElement("name")
            xmlDoc.WriteString(reader.Item("name"))
            xmlDoc.WriteEndElement()
            xmlDoc.WriteStartElement("author")
            xmlDoc.WriteString(reader.Item("author"))
            xmlDoc.WriteEndElement()
            xmlDoc.WriteStartElement("authorname")
            xmlDoc.WriteString(reader.Item("fullName"))
            xmlDoc.WriteEndElement()
            xmlDoc.WriteStartElement("year")
            xmlDoc.WriteString(reader.Item("studentYear"))
            xmlDoc.WriteEndElement()
            xmlDoc.WriteStartElement("description")
            xmlDoc.WriteString(reader.Item("description"))
            xmlDoc.WriteEndElement()
            xmlDoc.WriteStartElement("duemonth")
            xmlDoc.WriteString(reader.Item("duemonth"))
            xmlDoc.WriteEndElement()
            xmlDoc.WriteStartElement("dueday")
            xmlDoc.WriteString(reader.Item("dueday"))
            xmlDoc.WriteEndElement()

            xmlDoc.WriteEndElement()
        End While

        '-- close XML root
        xmlDoc.WriteEndElement()
        xmlDoc.WriteEndDocument()
        xmlDoc.Close()

        reader.Close()
        DBConnection.Close()

    End Sub

</script>
