/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Let's set some macro vars to help us save the report in HOME.   */

%let homepath=%sysget(HOME);
%put &=homepath;
%let now=%sysfunc(compress(%sysfunc(translate(%sysfunc(time(),time5.),.,:))));
%put &=now ;

*Import data;
proc import file="&HOMEPATH/data/2014_apple_stock.csv" 
     out=WORK.apple_stock replace;
run;


/* Plotly */

/* Read data as...

1. CSV file
2. CSV via URL
3. SAS dataset

*/

proc python;
submit;

import pandas as pd
import plotly.express as px

# Get macro vars here or directly in the code
homepathPY = SAS.symget("homepath")
nowPY = SAS.symget("now")
print("Now is: "+nowPY)
print("Path is: "+homepathPY)

# Read CSV, URL or SAS dataset
#df = pd.read_csv('https://raw.githubusercontent.com/plotly/datasets/master/2014_apple_stock.csv')
#df = pd.read_csv(homepathPY+'/data/2014_apple_stock.csv')
df = SAS.sd2df('WORK.apple_stock')

fig = px.line(df, x = 'AAPL_x', y = 'AAPL_y', title='Apple Share Prices over time (2014)')

plotly_file=homepathPY+'/AppleSharePrices-'+nowPY
#plotly_file=SAS.symget("homepath")+'/AppleSharePrices-'+SAS.symget("now")

fig.write_html(plotly_file+'.html')

fig.write_image(plotly_file+'.svg')
SAS.renderImage(plotly_file+'.svg')

# Does not work here, as the client does not run python
#fig.show()

endsubmit;
run;



/* Sankey */
proc python;
submit;

import plotly.graph_objects as go
import urllib.request, json

url = 'https://raw.githubusercontent.com/plotly/plotly.js/master/test/image/mocks/sankey_energy.json'
response = urllib.request.urlopen(url)
data = json.loads(response.read())

# override gray link colors with 'source' colors
opacity = 0.4
# change 'magenta' to its 'rgba' value to add opacity
data['data'][0]['node']['color'] = ['rgba(255,0,255, 0.8)' if color == "magenta" else color for color in data['data'][0]['node']['color']]
data['data'][0]['link']['color'] = [data['data'][0]['node']['color'][src].replace("0.8", str(opacity))
                                    for src in data['data'][0]['link']['source']]

fig = go.Figure(data=[go.Sankey(
    valueformat = ".0f",
    valuesuffix = "TWh",
    # Define nodes
    node = dict(
      pad = 15,
      thickness = 15,
      line = dict(color = "black", width = 0.5),
      label =  data['data'][0]['node']['label'],
      color =  data['data'][0]['node']['color']
    ),
    # Add links
    link = dict(
      source =  data['data'][0]['link']['source'],
      target =  data['data'][0]['link']['target'],
      value =  data['data'][0]['link']['value'],
      label =  data['data'][0]['link']['label'],
      color =  data['data'][0]['link']['color']
))])

fig.update_layout(title_text="Energy forecast for 2050<br>Source: Department of Energy & Climate Change, Tom Counsell via <a href='https://bost.ocks.org/mike/sankey/'>Mike Bostock</a>",
                  font_size=10)

fig.write_html(SAS.symget("homepath")+'/Sankey-'+SAS.symget("now")+'.html')

fig.write_image(SAS.symget("homepath")+'/Sankey-'+SAS.symget("now")+'.svg')
SAS.renderImage(SAS.symget("homepath")+'/Sankey-'+SAS.symget("now")+'.svg')

endsubmit;
run;
