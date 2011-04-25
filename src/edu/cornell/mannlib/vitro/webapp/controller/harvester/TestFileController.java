/* $This file is distributed under the terms of the license in /doc/license.txt$ */

package edu.cornell.mannlib.vitro.webapp.controller.harvester; 

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.json.JSONException;
import org.json.JSONObject;
import org.skife.csv.SimpleReader;

import edu.cornell.mannlib.vitro.webapp.config.ConfigurationProperties;
import edu.cornell.mannlib.vitro.webapp.controller.VitroRequest;
import edu.cornell.mannlib.vitro.webapp.controller.freemarker.FreemarkerHttpServlet;
import edu.cornell.mannlib.vitro.webapp.controller.freemarker.responsevalues.ExceptionResponseValues;
import edu.cornell.mannlib.vitro.webapp.controller.freemarker.responsevalues.ResponseValues;
import edu.cornell.mannlib.vitro.webapp.controller.freemarker.responsevalues.TemplateResponseValues;
import edu.cornell.mannlib.vitro.webapp.filestorage.backend.FileStorageSetup;
import edu.cornell.mannlib.vitro.webapp.filestorage.uploadrequest.FileUploadServletRequest;

public class TestFileController extends FreemarkerHttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Log log = LogFactory.getLog(TestFileController.class);
    private static final String TEMPLATE_DEFAULT = "testfile.ftl";

    @Override
    protected ResponseValues processRequest(VitroRequest vreq) {
        try {
            Map<String, Object> body = new HashMap<String, Object>();
            //body.put("uploadPostback", "false");
            body.put("processRequestTest", "hi.");
            return new TemplateResponseValues(TEMPLATE_DEFAULT, body);
        } catch (Throwable e) {
            log.error(e, e);
            return new ExceptionResponseValues(e);
        }
    }

    @Override
    protected String getTitle(String siteName, VitroRequest vreq) {
        return "VIVO Harvester Test";
    }


    @Override
    public void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException {

        int maxFileSize = 1024 * 1024;

        FileUploadServletRequest req = FileUploadServletRequest.parseRequest(request, maxFileSize);
        if(req.hasFileUploadException()) {
            Exception e = req.getFileUploadException();
            log.error(e, e);
            return;
        }

        Map<String, List<FileItem>> fileStreams = req.getFiles();

        JSONObject json = new JSONObject();

        String vitroHomeDirectoryName = ConfigurationProperties.getBean(request.getSession().getServletContext()).getProperty(FileStorageSetup.PROPERTY_VITRO_HOME_DIR);
        if (vitroHomeDirectoryName == null) {
            log.error("Vitro home directory name could not be found.");
            return;
        }

        String pathBase = vitroHomeDirectoryName + "/" + FileStorageSetup.FILE_STORAGE_SUBDIRECTORY + "/harvester/";

        String path = pathBase + getSessionId(request) + "/";
        File directory = new File(path);

        String firstUpload = req.getParameter("firstUpload"); //clear directory on first upload
        if(firstUpload.toLowerCase().equals("true")) {
            if(directory.exists()) {
                File[] children = directory.listFiles();
                for(File child : children) {
                    child.delete();
                }
            }
        }

        if(!directory.exists())
            directory.mkdirs();

        if(fileStreams.get("csvFile") != null && fileStreams.get("csvFile").size() > 0) {
            FileItem csvStream = fileStreams.get("csvFile").get(0);
            String name = csvStream.getName();
            name = handleNameCollision(path, name, directory);
            File file = new File(path + name);
            try {
                csvStream.write(file);
            } catch (Exception e) {                               
                log.error(e, e);
                return;
            } finally {           
                csvStream.delete();
            }

            String errorMessage = validateCsvFile(file);
            boolean success;
            if(errorMessage != null) {
                success = false;
                file.delete();
            } else {
                success = true;
                errorMessage = "success";
            }


            try {
                json.put("success", success);
                json.put("fileName", name);
                json.put("errorMessage", errorMessage);
            }
            catch(JSONException e) {
                log.error(e, e);
                return;
            }

        } else {
            try {
                json.put("success", false);
                json.put("fileName", "(none)");
                json.put("errorMessage", "No file uploaded");
            } catch(JSONException e) {
                log.error(e, e);
                return;
            }

        }

        response.getWriter().write(json.toString());
    }
    
    private String handleNameCollision(String path, String filename, File directory) {
        String base = filename;
        String extension = "";
        if(filename.contains(".")) {
            base = filename.substring(0, filename.lastIndexOf("."));
            extension = filename.substring(filename.indexOf("."));
        }
        
        String renamed = filename;
        
        for(int i = 1; new File(path + renamed).exists(); i++) {
            renamed = base + " (" + String.valueOf(i) + ")" + extension;
        }
        
        return renamed;
    }


    private String getSessionId(HttpServletRequest request) {
        return request.getSession().getId();
    }


    private String validateCsvFile(File file) {
        try {
            SimpleReader reader = new SimpleReader();
            List csv = reader.parse(file);
            int length = csv.size();
            
            if(length == 0)
                return "No data in file";
            
            for(int i = 0; i < length; i++) {
                String[] line = (String[])csv.get(i);
                if(i == 0) {
                    String errorMessage = validateCsvFirstLine(line);
                    if(errorMessage != null)
                        return errorMessage;
                }
                else if(line.length != 0) {
                    if(line.length != 2)
                        return "Mismatch in number of entries in row " + i;
                }
            }

        } catch (IOException e) {
            log.error(e, e);
            return e.getMessage();
        }
        return null;
    }
    
    private String validateCsvFirstLine(String[] line) {
        String errorMessage = "File header does not match specification";
        if(line.length != 2)
            return errorMessage;
        if(!line[0].equals("firstName"))
            return errorMessage;
        if(!line[1].equals("lastName"))
            return errorMessage;
        return null;
    }

}
