

/* PLOTLY Line basic  */

proc fcmp;
declare object py(python);
submit into py;

import pandas as pd
import plotly.express as px

def plot(var1):
    "Output: rc"

#    df = pd.read_csv('C:/Demo/Python/2014_apple_stock.csv')
    df = pd.read_csv('https://raw.githubusercontent.com/plotly/datasets/master/2014_apple_stock.csv')

    fig = px.line(df, x = 'AAPL_x', y = 'AAPL_y', title='Apple Share Prices over time (2014)')

#Write to disk or open in browser  
#    fig.write_html('c:/temp/AppleSharePrices-2014.html')
    fig.show()

    rc = 0
    return rc

endsubmit;
rc = py.publish();
rc = py.call("plot", 1);
MyResult = py.results["rc"];
put MyResult=;
run;




%let homepath=C:\temp; *%sysget(HOME);
%put &=homepath;
%let now=%sysfunc(time(),5.);
%put &=now ;




/* - - - - - - - - - - */
/* A bit more control  */
/* - - - - - - - - - - */


*Import CSV ;
proc import file="C:/Demo/Python/2014_apple_stock.csv" 
     out=work.apple_stock;
run;


*Some parameters to pass into the py func ;

%let workpath = %sysfunc(pathname(work));
%put &=workpath;
%let DatasetName = %str(&WORKPATH.\apple_stock.sas7bdat);
%put &=DatasetName;


proc fcmp;
declare object py(python);
submit into py;
import pandas as pd
import plotly.express as px
import pyreadstat

def plot(homepath, now, datasetname):
    "Output: rc"

# Read file, url or SAS dataset 
#    df = pd.read_csv('C:/Demo/Python/2014_apple_stock.csv')
#    df = pd.read_csv('https://raw.githubusercontent.com/plotly/datasets/master/2014_apple_stock.csv')
    df, meta = pyreadstat.read_sas7bdat(datasetname)

    fig = px.line(df, x = 'AAPL_x', y = 'AAPL_y', title='Apple Share Prices over time (2014)')

#    fig.write_html('c:/temp/AppleSharePrices-2014.html')
    fig.show()

    rc = 0
    return rc

endsubmit;

rc = py.publish();
rc = py.call("plot", "&HOMEPATH", "&NOW", "&DATASETNAME");

MyResult = py.results["rc"];
put MyResult=;
run;




