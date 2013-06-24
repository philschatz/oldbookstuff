ROOT=$(pwd)
XSL_DIR="${ROOT}/rhaptos.cnxmlutils/rhaptos/cnxmlutils/xsl"

# Check commandline arguments and environment before running
if [ -z $1 ]; then
  echo 'This file takes exactly 2 arguments:'
  echo '1. A string representing the book title (usually "col11448@1.7")'
  echo '2. The path to an unzipped complete zip from http://cnx.org (ie http://cnx.org/content/col11448/latest/complete)'
  echo ''
  echo 'It also requires a copy of http://github.com/Connexions/rhaptos.cnxmlutils/'
  echo 'to be checked out in the current directory.'
  exit 1
fi

# Make sure "rhaptos.cnxmlutils exists"
if [ ! -d ${XSL_DIR} ]; then
  echo "${XSL_DIR} does not exist!"
  echo 'Please obtain a copy from http://github.com/Connexions/rhaptos.cnxmlutils'
  exit 2
fi


COLLECTION=$1
cd $2

MODULES=$(ls|grep "^m")


# A little XSL file that extracts the title from a module
TITLES_XSL='''
  <xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:c="http://cnx.rice.edu/cnxml"
    version="1.0">

  <xsl:output omit-xml-declaration="yes" encoding="ASCII"/>

  <xsl:template match="/">
    <xsl:value-of select="c:document/c:title/text()"/>
  </xsl:template>

  </xsl:stylesheet>
'''


# OPF File header
echo '<?xml version="1.0" encoding="UTF-8"?>' > ${COLLECTION}.opf
echo '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" xml:lang="en" unique-identifier="pub-id" prefix="cc: http://creativecommons.org/ns#">' >> ${COLLECTION}.opf
echo '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">' >> ${COLLECTION}.opf
echo "    <dc:title id=\"title\">${COLLECTION}</dc:title>" >> ${COLLECTION}.opf
echo '    <meta refines="#title" property="title-type">main</meta>' >> ${COLLECTION}.opf
echo '    <dc:creator id="creator">Connexions</dc:creator>' >> ${COLLECTION}.opf
echo '    <meta refines="#creator" property="file-as">Connexions</meta>' >> ${COLLECTION}.opf
echo "    <dc:identifier id=\"pub-id\">org.cnx.${COLLECTION}</dc:identifier>" >> ${COLLECTION}.opf
echo '    <dc:language>en-US</dc:language>' >> ${COLLECTION}.opf
echo '    <meta property="dcterms:modified">2013-06-23T12:47:00Z</meta>' >> ${COLLECTION}.opf
echo '    <dc:publisher>Connexions</dc:publisher>' >> ${COLLECTION}.opf
echo '    <dc:rights>This work is shared with the public using the Attribution 3.0 Unported (CC BY 3.0) license.</dc:rights>' >> ${COLLECTION}.opf
echo '    <link rel="cc:license" href="http://creativecommons.org/licenses/by/3.0/"/>' >> ${COLLECTION}.opf
echo '    <meta property="cc:attributionURL">http://cnx.org/content</meta>' >> ${COLLECTION}.opf
echo '  </metadata>' >> ${COLLECTION}.opf
echo '  <manifest>' >> ${COLLECTION}.opf
echo "    <item id=\"toc\" properties=\"nav\" href=\"${COLLECTION}-toc.xhtml\" media-type=\"application/xhtml+xml\"/>" >> ${COLLECTION}.opf

# ToC Navigation doc
HTML=$(xsltproc ${XSL_DIR}/collxml-to-html5.xsl collection.xml 2> /dev/null)
echo '<?xml version="1.0" encoding="UTF-8"?>' > ${COLLECTION}-toc.xhtml
echo "<html xmlns=\"http://www.w3.org/1999/xhtml\"><body>" >> ${COLLECTION}-toc.xhtml
echo ${HTML} >> ${COLLECTION}-toc.xhtml
echo "</body></html>" >> ${COLLECTION}-toc.xhtml


for ID in ${MODULES}; do
  TITLE=$(echo ${TITLES_XSL} | xsltproc - ${ID}/index.cnxml)
  HTML=$(xsltproc ${XSL_DIR}/cnxml-to-html5.xsl ${ID}/index.cnxml 2> /dev/null)

  # XHTML File
  echo '<?xml version="1.0" encoding="UTF-8"?>' > ${ID}.xhtml
  echo "<html xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>${TITLE}</title></head>" >> ${ID}.xhtml
  echo ${HTML} >> ${ID}.xhtml
  echo '</html>' >> ${ID}.xhtml

  # OPF File manifest entry
  echo "    <item media-type=\"application/xhtml+xml\" id=\"${ID}\" href=\"${ID}.xhtml\"/>" >> ${COLLECTION}.opf

  echo "Done with ${ID}"
done


# OPF File spine start
echo '  </manifest>' >> ${COLLECTION}.opf
echo '  <spine>' >> ${COLLECTION}.opf
echo '    <itemref linear="no" idref="toc"/>' >> ${COLLECTION}.opf


for ID in ${MODULES}; do
  # OPF File spine entry
  echo "    <itemref linear=\"yes\" idref=\"${ID}\"/>" >> ${COLLECTION}.opf
done


# OPF File footer
echo '  </spine>' >> ${COLLECTION}.opf
echo '</package>' >> ${COLLECTION}.opf

cd ${XSL_DIR}
