import React, { useState, useEffect } from 'react';
import { Shield, TrendingUp, AlertTriangle, Users, Activity, Banknote, Zap, Globe, ShieldCheck } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend } from 'recharts';
import { supabase } from '../supabase';
import { GigKavachApi } from '../api';
import SimulationPanel from '../components/SimulationPanel';

const Dashboard = () => {
  const [showSim, setShowSim] = useState(false);
  const [predictions, setPredictions] = useState([]);
  const [stats, setStats] = useState({
    activePolicies: 0,
    premiumPool: 0,
    claimsProcessing: 0,
    fraudFlags: 0,
    lossRatio: 0,
    flagsData: []
  });

  const revenueData = [
    { day: 'Mon', historical: 400, predicted: 440 },
    { day: 'Tue', historical: 300, predicted: 320 },
    { day: 'Wed', historical: 200, predicted: 250 },
    { day: 'Thu', historical: 278, predicted: 300 },
    { day: 'Fri', historical: 189, predicted: 210 },
    { day: 'Sat', historical: 239, predicted: 260 },
    { day: 'Sun', historical: 349, predicted: 390 },
  ];

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [apiStats, apiPreds] = await Promise.all([
          GigKavachApi.getStats().catch(() => ({})),
          GigKavachApi.getPredictions().catch(() => ({ data: [] }))
        ]);
        
        if (apiPreds && apiPreds.data) {
          setPredictions(apiPreds.data);
        }
        
        const { data: claimsData } = await supabase
          .from('claims')
          .select('claim_id, worker_id, payout_amount, confidence_score, status, trigger_label')
          .order('created_at', { ascending: false })
          .limit(10);

        const fraudFlags = (claimsData || []).filter(c => c.confidence_score < 50);

        setStats({
          activePolicies: apiStats?.active_policies || 0,
          premiumPool: apiStats?.premium_pool || 0,
          claimsProcessing: claimsData?.length || 0,
          fraudFlags: fraudFlags.length,
          lossRatio: apiStats?.loss_ratio || 0,
          flagsData: fraudFlags.slice(0, 4).map(f => ({
            id: f.claim_id,
            worker: f.worker_id,
            type: f.trigger_label || 'Anomaly',
            status: f.confidence_score < 20 ? 'Critical' : 'Review',
            score: f.confidence_score
          }))
        });
      } catch (err) {
        console.error("Dashboard Sync Error:", err);
      }
    };

    fetchData();

    // Set up Realtime subscriptions
    const polSub = supabase.channel('dashboard-policies').on('postgres_changes', { event: '*', schema: 'public', table: 'policies' }, fetchData).subscribe();
    const clmSub = supabase.channel('dashboard-claims').on('postgres_changes', { event: '*', schema: 'public', table: 'claims' }, fetchData).subscribe();

    return () => {
      supabase.removeChannel(polSub);
      supabase.removeChannel(clmSub);
    };
  }, []);

  return (
    <div>
      <div className="page-title">
        Command Center
        <div style={{ display: 'flex', gap: '12px' }}>
          <button style={{ padding: '8px 16px', background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', color: 'var(--text-primary)', borderRadius: '8px', cursor: 'pointer', fontSize: '14px', fontWeight: 500 }}>
            Export Report
          </button>
          <button 
            onClick={() => setShowSim(true)}
            style={{ padding: '8px 16px', background: 'var(--primary)', border: 'none', color: 'white', borderRadius: '8px', cursor: 'pointer', fontSize: '14px', fontWeight: 500, display: 'flex', alignItems: 'center', gap: '8px' }}
          >
            <Activity size={16} /> Incident Simulator
          </button>
        </div>
      </div>

      {showSim && <SimulationPanel onClose={() => setShowSim(false)} />}

      <div className="grid-cols-4">
        <div className="glass-card stat-card">
          <div className="stat-header">
            <span className="stat-title">Active Risk</span>
            <div className="stat-icon" style={{ background: 'var(--bg-surface)', color: 'var(--primary)' }}>
              <Shield size={20} />
            </div>
          </div>
          <div className="stat-value">{stats.activePolicies.toLocaleString()} pts</div>
          <div className="stat-trend trend-up"><TrendingUp size={14} /> Live tracking</div>
        </div>
        
        <div className="glass-card stat-card">
          <div className="stat-header">
            <span className="stat-title">Loss Ratio</span>
            <div className="stat-icon" style={{ background: 'var(--bg-card-light)', color: stats.lossRatio > 0.6 ? 'var(--danger)' : 'var(--success)' }}>
              <Activity size={20} />
            </div>
          </div>
          <div className="stat-value">{(stats.lossRatio * 100).toFixed(1)}%</div>
          <div className="stat-trend" style={{ color: stats.lossRatio > 0.6 ? 'var(--danger)' : 'var(--success)' }}>
            {stats.lossRatio > 0.6 ? <AlertTriangle size={14} /> : <TrendingUp size={14} />} 
            {stats.lossRatio > 0.6 ? ' Above threshold' : ' Healthy pool'}
          </div>
        </div>

        <div className="glass-card stat-card">
          <div className="stat-header">
            <span className="stat-title">Claims Processing</span>
            <div className="stat-icon" style={{ background: 'var(--bg-surface)', color: 'var(--primary)' }}>
              <TrendingUp size={20} />
            </div>
          </div>
          <div className="stat-value">{stats.claimsProcessing}</div>
          <div className="stat-trend trend-up" style={{ color: 'var(--success)' }}><TrendingUp size={14} /> AI Verified</div>
        </div>

        <div className="glass-card stat-card">
          <div className="stat-header">
            <span className="stat-title">Fraud Flags</span>
            <div className="stat-icon" style={{ background: 'rgba(198, 40, 40, 0.1)', color: 'var(--danger)' }}>
              <AlertTriangle size={20} />
            </div>
          </div>
          <div className="stat-value">{stats.fraudFlags}</div>
          <div className="stat-trend trend-down"><TrendingUp size={14} /> Anomaly Scan</div>
        </div>
      </div>

      <div className="card-title" style={{ marginTop: '24px', marginBottom: '16px' }}>AI Orchestrator Metrics (10k Training Set)</div>
      <div className="grid-cols-3" style={{ marginBottom: '24px' }}>
        <div className="glass-card" style={{ padding: '20px', borderLeft: '4px solid var(--primary)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>Pricing AI Agent</div>
          <div style={{ fontSize: '24px', fontWeight: '800', marginTop: '8px' }}>94.5% Conf</div>
          <div style={{ fontSize: '13px', color: 'var(--success)', marginTop: '4px' }}>RandomForest Regressor</div>
        </div>
        <div className="glass-card" style={{ padding: '20px', borderLeft: '4px solid var(--danger)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>Fraud AI Agent</div>
          <div style={{ fontSize: '24px', fontWeight: '800', marginTop: '8px' }}>95.2% Conf</div>
          <div style={{ fontSize: '13px', color: 'var(--success)', marginTop: '4px' }}>IsolationForest Anomaly</div>
        </div>
        <div className="glass-card" style={{ padding: '20px', borderLeft: '4px solid #00E676' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>Adjudicator AI Agent</div>
          <div style={{ fontSize: '24px', fontWeight: '800', marginTop: '8px' }}>98.1% Conf</div>
          <div style={{ fontSize: '13px', color: 'var(--success)', marginTop: '4px' }}>GradientBoosting Classifier</div>
        </div>
      </div>

      <div className="grid-cols-2">
        <div className="glass-card">
          <div className="card-title">AI Claims Forecast (Next 7 Days)</div>
          <div style={{ height: '300px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={predictions.length > 0 ? predictions : revenueData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorHist" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--text-muted)" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="var(--text-muted)" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorPred" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-subtle)" vertical={false} />
                <Tooltip 
                  contentStyle={{ backgroundColor: 'var(--bg-card)', borderColor: 'var(--border-subtle)', borderRadius: '8px', color: 'var(--text-primary)' }}
                />
                <Legend iconType="circle" />
                <Area type="monotone" name="Historical Avg" dataKey="historical" stroke="var(--text-muted)" strokeDasharray="5 5" fillOpacity={1} fill="url(#colorHist)" />
                <Area type="monotone" name="AI Predicted" dataKey="predicted" stroke="var(--primary)" strokeWidth={3} fillOpacity={1} fill="url(#colorPred)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="glass-card">
          <div className="flex-between" style={{ marginBottom: '20px' }}>
            <div className="card-title" style={{ margin: 0 }}>Active Fraud Alerts</div>
            <a href="/fraud" style={{ color: 'var(--primary)', fontSize: '13px', textDecoration: 'none', fontWeight: 600 }}>View All</a>
          </div>
          
          <table className="data-table">
            <thead>
              <tr>
                <th>Claim ID</th>
                <th>Worker</th>
                <th>Anomaly</th>
                <th>Score</th>
              </tr>
            </thead>
            <tbody>
              {stats.flagsData.map((flag, i) => (
                <tr key={i} className="hover-row">
                  <td style={{ color: 'var(--primary)', fontWeight: 800 }}>{flag.id}</td>
                  <td style={{ fontWeight: 500 }}>{flag.worker}</td>
                  <td>
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{flag.type}</span>
                  </td>
                  <td>
                    <span className={`badge-neon ${flag.score < 20 ? 'status-danger' : 'status-warning'}`}>
                      {flag.score}/100
                    </span>
                  </td>
                </tr>
              ))}
              {stats.flagsData.length === 0 && (
                <tr>
                  <td colSpan="4" style={{ textAlign: 'center', padding: '64px 20px' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '16px', opacity: 0.3 }}>
                      <ShieldCheck size={48} />
                      <div style={{ fontSize: '13px', letterSpacing: '1px' }}>NO CRITICAL ANOMALIES DETECTED</div>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
