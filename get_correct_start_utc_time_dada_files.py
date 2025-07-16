import pandas as pd
df = pd.read_csv('results_NGC1851.txt', sep='\s+')
#df = pd.read_csv('results_NGC6544.txt', sep='\s+')

#df contains start time per bridge per RX buffer pair.
#Goal 1 -> Find the start time of each bridge. So across all RX buffers, find the minimum start time.
#J0437 = df.loc[(df['UTC'] == '2024-05-19T15:40:47Z') | (df['UTC'] == '2024-05-19T15:40:48Z')]
#J1909 = df.loc[(df['UTC'] == '2024-05-23T02:54:56Z') | (df['UTC'] == '2024-05-23T02:54:57Z')]
#J1909 = df.loc[(df['UTC'] == '2024-05-23T02:54:56Z')]
NGC1851 = df.loc[(df['UTC'] == '2024-05-19T15:50:07Z')]
min_time_per_bridge = NGC1851.groupby('Bridge')['Time_Min'].min().reset_index()

#For test pulsars, sometimes a certain bridge may never start until the next scan begins, then look for the last bridge that started for the time-period of the test pulsar can
#test = min_time_per_bridge.sort_values(by='Time_Min', ascending=False)

#Drop Nan columns
#test = test.dropna()
#test = test.reset_index(drop=True)
#bridge_list = test['Bridge'].tolist()
#bridge_list.sort()
#print(bridge_list)
#
#test.to_csv('min_time_per_bridge_J1909.txt', sep=' ', index=False)


#We start creating dada files when all the bridges have started recording, so now find the maximum value of 'Time_Min'

max_time = min_time_per_bridge['Time_Min'].max()

print(f"All the bridges have started recording at {max_time}")
print("Pass this to timestamp_to_utc.py to get the utc time of dada recording, subtract that from the start time in the bvruse meta file to get number of samples to skip, which goes to asgard")
