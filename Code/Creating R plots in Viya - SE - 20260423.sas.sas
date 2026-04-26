/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Let's set some macro vars to help us save the report in HOME.   */

%let homepath=%sysget(HOME);
%put &=homepath;
%let now=%sysfunc(compress(%sysfunc(translate(%sysfunc(time(),time5.),.,:))));
%put &=now ;


/* - - - - - - - - - - - - - - - - */
/* ggplot2                         */
/* - - - - - - - - - - - - - - - - */
proc r;
submit;

library(ggplot2)

df <- data.frame(
  category = rep(c("A", "B", "C", "D"), each = 25),
  value = c(rnorm(25, 10, 2),
            rnorm(25, 15, 3),
            rnorm(25, 12, 2.5),
            rnorm(25, 18, 4))
)

p <- ggplot(df, aes(x = category, y = value, fill = category)) +
  geom_boxplot(alpha = 0.7) +
  theme_minimal() +
  labs(title = "Distribution by Category",
       x = "Category",
       y = "Value") +
  scale_fill_brewer(palette = "Set2")


rplot(p, filename = "boxplot_demo.png")

endsubmit;
run;


/* Importera SASHELP.CARS, skapa och spara plott */
proc R;
submit;

library(ggplot2)

cars_df <- sd2df("sashelp.cars")

p1 <- ggplot(cars_df, aes(x = Weight, y = MPG_City)) +
  geom_point(aes(color = Type), alpha = 0.6, size = 3) +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  theme_minimal() +
  labs(title = "Fuel Efficiency vs Weight",
       x = "Weight (lbs)",
       y = "City MPG")

# Visa plotten i Results
rplot(p1, filename = "scatter_mpg.png")

endsubmit;
run;



/* Visa tidigare sparad plott */
proc R;
submit;

library(ggplot2)
data <- data.frame(
  x = seq(0, 10, 0.1),
  y = sin(seq(0, 10, 0.1))
)

p <- ggplot(data, aes(x = x, y = y)) +
  geom_line(color = "purple", size = 1.5) +
  geom_point(color = "orange", size = 2) +
  theme_classic() +
  labs(title = "Sine Wave Visualization",
       x = "X", y = "sin(X)")

plotfile <- paste0(sas$workpath, "sine_wave.png")
print(plotfile)

# Spara image
ggsave(plotfile, p, width = 8, height = 5, dpi = 150)

# Visa plott i Results
renderImage(plotfile)

endsubmit;
run;


/* - - - - - - - - - - - - - - - - */
/* Base R                          */
/* - - - - - - - - - - - - - - - - */
proc R;
submit;

rplot(quote(plot(mtcars$mpg, mtcars$wt,
                 main = "MPG vs Weight",
                 xlab = "Weight (1000 lbs)",
                 ylab = "Miles per Gallon",
                 col = "blue", 
                 pch = 19,
                 cex = 1.5)),
     filename = "cars_scatter.png")

endsubmit;
run;
