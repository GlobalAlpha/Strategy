# Data processing
import pandas as pd
import datetime

# eligible currencies to construct the portfolio - Top 10
CCY = ['BTC','ETH','XRP','USDT','BCH','BSV','LTC','BNB','EOS','XTZ']
# window for rebalance
window = 30
# window for calculating the volatility and momentum factors
vol1_window = 30
vol2_window = 90
mom1_window = 90
mom2_window = 180
# date range for back-testing
new_datetime_range = pd.date_range(start='2019-07-01', freq="1D", end=datetime.date.today())

for c in CCY:
    # path of the raw data download (FTX historical data)
    path = '/Users/huiwenli/GAC/FTX/Rest/history_'+c+'-PERP.csv'
    df = pd.read_csv(path)
    # prepare data by index the date and calculate daily return
    df.startTime = df.startTime.apply(lambda x: x[:19])
    df.startTime = pd.to_datetime(df.startTime, format='%Y-%m-%dT%H:%M:%S')
    df['date'] = pd.to_datetime([datetime.datetime.date(d) for d in df['startTime']])
    df.set_index('date', inplace=True)
    df = df.reindex(new_datetime_range)
    df['return'] = (df.close - df.close.shift(1))/df.close.shift(1)

    # calculate each factor
    df['agg_volume'] = df['volume'].rolling(window).sum()
    df['ret'] = (df['close'] - df['close'].shift(window-1))/df['close'].shift(window-1)
    df['vol1'] = df['return'].rolling(vol1_window).std()
    df['vol2'] = df['return'].rolling(vol2_window).std()
    df['mom1'] = (df['close'] - df['close'].shift(mom1_window-1))/df['close'].shift(mom1_window-1)
    df['mom2'] = (df['close'] - df['close'].shift(mom2_window-1))/df['close'].shift(mom2_window-1)


    # resample to each rebalancing date
    x = df.resample(str(window)+'D')['close','ret','agg_volume','vol1','vol2','mom1','mom2'].tail(1)
    x['ccy'] = c
    x['weight'] = 1/len(CCY)
    x.index.name = 'date'
    new_file = 'data_30_'+c+'.csv'
    x.to_csv(new_file)
