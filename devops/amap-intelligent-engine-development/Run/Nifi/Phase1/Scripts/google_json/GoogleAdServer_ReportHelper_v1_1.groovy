/**@ ------------------------------------------------------------------ *
* Script to add extra columns with hardcoded values in AdServer Reports *
*                                                                       *
*This Script modifies the flowFile, replaces header and add             *
*hardcoded values for newly added extra columns                         *
*                                                                       *
* -------------------------------------------------------------------@**/ 

// Utilities
import org.apache.commons.io.IOUtils
import java.nio.charset.StandardCharsets

// Create new Flow File
flowFile = session.get()
if(!flowFile) return

// Read Parameters
def newheader=newheader.evaluateAttributeExpressions().getValue()
def addedvalues=addedvalues.evaluateAttributeExpressions().getValue()

// Add NewHeader and Hardcoded values which were passed as parameters
flowFile = session.write(flowFile, {inputStream, outputStream ->
inputStream.eachLine { line, number ->
        if (number == 1)
			   outputStream.write((newheader + "\n").getBytes(StandardCharsets.UTF_8))
		else
		   outputStream.write((line + addedvalues + "\n").getBytes(StandardCharsets.UTF_8))
   }
} as StreamCallback)

// Add Name of the final file
flowFile = session.putAttribute(flowFile, "tablename", namefile.evaluateAttributeExpressions().getValue())
session.transfer(flowFile, REL_SUCCESS)