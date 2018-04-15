/**
 * Created by neilwang on 2017/4/23.
 */
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;
import java.util.Scanner;
import java.util.Locale;
//import java.util.

public class LearnIO {
    public static void main(String[] args) throws IOException {
        Scanner s = null;
        double sum = 0;

        try {
            s = new Scanner(new BufferedReader(new FileReader("/Users/neilwang/git/rep1/java-learn/java-learn-io/usnumbers.txt")));
            s.useLocale(Locale.US);
            //Scanner t = new Scanner()

            while(s.hasNext()){
                if(s.hasNextDouble()){
                    double temp = s.nextDouble();
                    System.out.println(temp);
                    sum += temp;
                }
                else
                {
                    System.out.println(s.nextLine());

                }
            }
        }
        finally {
            s.close();
        }
        System.out.println(sum);
        //System.out.println("Hello World");
    }
}
