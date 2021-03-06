ttls = [3:12:127 127];

pdrs72 = 100*[1,0.9667,0.9667,0.9583,0.9667,0.9833,0.9833,0.9667,0.975,0.9833,0.9667,0.9667];
pdrs48 = 100*[0.9583,0.975,0.975,0.975,0.975,0.975,0.9667,0.975,0.9667,0.9667,0.975,0.975];
pdrs35 = 100*[0.9417,0.9583,0.975,0.9583,0.9833,0.9667,0.975,0.9583,0.9917,0.9583,0.975,0.975];
pdrs22 = 100*[1,0.9583,0.9833,0.9833,0.9833,0.9833,0.9833,0.9833,0.9833,0.9833,0.9833,0.9833];
pdrs11 = 100*[0.7167,0.6833,0.6833,0.6833,0.6833,0.6833,0.6833,0.6833,0.6833,0.6833,0.6833,0.6833];

figure
plot(ttls, pdrs72, '-o', ttls, pdrs48, 'g-+',ttls, pdrs35, '-*', ttls, pdrs22, 'r-s', ttls, pdrs11, '-d')
% plot(ttls, pdrs72, '-o', ttls, pdrs48, 'g-+',ttls, pdrs35, '-*', ttls, pdrs22, 'r-s')

xlabel('TTL')
ylabel('PDR (%)')
legend({'72 relays', '48 relays', '35 relays', '22 relays', '11 relays'},'Location','southeast','NumColumns',2)
xticks(ttls)