rm(list=ls())
gc()
require('data.table')
require('ggplot2')

# set your working directory
setwd('/Users/huiwenli/Downloads')

#load the factor data
Data = fread('ftx_fct_30.csv')

#set date format
#Data$date=as.Date(Data$date,"%d/%m/%Y")
Data$date=as.Date(Data$date,"%Y-%m-%d")

setorder(Data, date, ccy)
Data = melt(Data, id.vars = c('date','ccy', 'weight', 'ret', 'close'), 
            measure.vars = c('agg_volume', 'mom1', 'mom2','vol1', 'vol2'))
Data[, ':=' (S1 = (value - mean(value, na.rm=T))/sd(value, na.rm=T),
             S2 = (value - median(value, na.rm=T))/median(abs(value-median(value, na.rm=T)), na.rm=T),
             S3 = frankv(value, ties.method='average', na.last='keep', order = 1)), by=.(date, variable)]
Data[, S3 := S3/max(S3, na.rm=T), by=.(date, variable)]
dat = dcast(Data, date+ccy+weight+ret+close~variable, value.var = 'S3')
dat[, ':=' (Comp_Mom = (ifelse(is.na(mom1), 0, mom1) + ifelse(is.na(mom2), 0, mom2)) 
            / ifelse( is.na(mom1)&is.na(mom2), NA, (ifelse(is.na(mom1), 0, 1) + ifelse(is.na(mom2), 0, 1)) ),
            Comp_Vol = (ifelse(is.na(vol1), 0, vol1) + ifelse(is.na(vol2), 0, vol2)) 
            / ifelse( is.na(vol1)&is.na(vol2), NA, (ifelse(is.na(vol1), 0, 1) + ifelse(is.na(vol2), 0, 1)) ) )]
dat[, Comp := agg_volume + Comp_Mom + Comp_Vol]

###### Assgin basket
fractile <- function(x, n) {
  if (sum(!is.na(x)) < n) { return(rep(1L*NA, length(x))) }
  rnk = rank(x, ties.method='first', na.last='keep')
  qnt = quantile(rnk, probs=seq(0, 1, length.out=n+1), na.rm=T, names=F)
  cut(rnk, breaks=qnt, include.lowest=T, labels=F, right=F)
}

NoBas = 3

dat[, Basket := fractile(Comp, NoBas), by=.(date)]
#cyp_bsk = dcast(dat, date~ccy, value.var = 'Basket')
#output basket info
write.csv(dat, 'ftx_basket_30.csv')

####### Calculate performance
Perf2=dat[,sum(weight*ret,na.rm=T)/sum(ifelse(is.na(ret),0,weight)), by = .(date, Basket)]
Perf2

BMPerf2 = dat[, sum(weight*ret, na.rm=T)/sum(ifelse(is.na(ret), 0, weight)), by = date]
setnames(BMPerf2, c('date', 'BM'))
BMPerf2

setkey(BMPerf2, date)
setkey(Perf2, date)

Perf2[, RelRtn2 := V1] 
Perf2 = dcast(Perf2, date~Basket, value.var = 'RelRtn2') 
Perf2 = BMPerf2[Perf2]
setnames(Perf2, c('date', 'BM', 'NA', 'Low', 'Mid', 'High'))
Perf2[, LS:=High-Low]
Perf2 = Perf2[!is.na(LS),]
Perf2 = melt(Perf2, id.vars = 'date') 

######## Plot cumulative performance
setorder(Perf2, date)			 
CumP2 = Perf2[, .(date = date, CumPerf2 = cumsum(value)), by=variable]
CumP2 = CumP2[!is.na(CumPerf2), ]
setnames(CumP2, c('NBasket', 'Date', 'Cum.Perf2'))

p = ggplot(data = CumP2[NBasket %in% c('Low', 'High','LS', 'BM')], aes(x = Date, y = Cum.Perf2)) 
p = p + geom_line(aes(group=NBasket, color = NBasket), size = 1)
p = p + theme_bw(base_family = 'Times')
print(p)