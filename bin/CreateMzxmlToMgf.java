import java.io.File;
import java.lang.String;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.util.Scanner;
import java.lang.Integer;

public class CreateMzxmlToMgf {
	
	static StringBuffer WiffMzmlBatFile = new StringBuffer();
	static StringBuffer WiffMzmlBatFileMain = new StringBuffer();
	
	public static void main( String [] args ) {
   
		//outputDir = args[0]
		//fastaFile = args[1]
		//ppm = args[2]
		//enzyme = args[3]
		//modsFileLocation = args[4]
		//MsgfplusJarDir = args[5]
	
		File outputDir = new File(args[0]);
		File[] files = outputDir.listFiles();
		String mParallelPath = args[1]+"\\mParallel\\MParallel.exe";
		String DIAUmpireSEJar = args[2];
		String MzxmlToMgfParams = args[3];
		int numOfFiles = 0;
		
		for( File file : files ) {
			if( !file.isDirectory() && (file.getAbsolutePath().endsWith(".mzXML")) ) {

				WiffMzmlBatFile.append("java").append(" ");
				WiffMzmlBatFile.append("-Xmx128G").append(" ");
				WiffMzmlBatFile.append("-jar").append(" ");
				WiffMzmlBatFile.append("\"").append(DIAUmpireSEJar).append("\"").append(" ");
				WiffMzmlBatFile.append(file).append(" ");
				WiffMzmlBatFile.append("\"").append(MzxmlToMgfParams).append("\"");
				WiffMzmlBatFile.append(" : ");
				numOfFiles++;
			}
		}
		
		
		if(numOfFiles != 0) {
			WiffMzmlBatFileMain.append(mParallelPath).append(" ");
			WiffMzmlBatFileMain.append("--count=" + numOfFiles + " ");
			WiffMzmlBatFileMain.append("--shell ");
			WiffMzmlBatFileMain.append(WiffMzmlBatFile);
			WiffMzmlBatFileMain.delete(WiffMzmlBatFileMain.length()-3, WiffMzmlBatFileMain.length());
			WiffMzmlBatFileMain.append("\r\n");
		}
		
		writeToFile(outputDir);
		
	}
	
	private static void writeToFile( File outputDir ) {
		String MSGFBatFilePath = outputDir.toString() + "\\MzxmlToMgf.bat";
		try {
			BufferedWriter bufwriter = new BufferedWriter( new FileWriter(MSGFBatFilePath) );
			bufwriter.write(WiffMzmlBatFileMain.toString());
			bufwriter.close();
		} catch( Exception e ) {
			e.printStackTrace();
		}
	}
}