%let homepath=%sysget(HOME);
%put &=homepath;
%let now=%sysfunc(time(),time5.);
%put &=now ;

*Import CSV;
proc import file="&HOMEPATH/data/2014_apple_stock.csv" 
     out=WORK.apple_stock replace;
run;


/* - - - - - - - - - */
/* Plotly line plot  */
/* - - - - - - - - - */

/* Read data

1. CSV from disc
2. CSV via URL
3. SAS dataset

*/

proc python;
submit;

import pandas as pd
import plotly.express as px

# Get macro vars 
homepathPY = SAS.symget("homepath")
now = SAS.symget("now")
print(now)
print("path: "+homepathPY)

# Read file, url or dataset 
df = pd.read_csv('https://raw.githubusercontent.com/plotly/datasets/master/2014_apple_stock.csv')
#df = pd.read_csv(homepathPY+'/data/2014_apple_stock.csv')
#df = SAS.sd2df('WORK.apple_stock')

fig = px.line(df, x = 'AAPL_x', y = 'AAPL_y', title='Apple Share Prices over time (2014)')

#Use py vars or get SAS macro vars 
#fig.write_html(homepathPY+'/AppleSharePrices-'+now+'.html')
fig.write_html(SAS.symget("homepath")+'/AppleSharePrices-'+now+'.html')

endsubmit;
run;


