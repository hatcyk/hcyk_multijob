import React, { useState, useEffect } from 'react';
import { debugData } from "../utils/debugData";
import { fetchNui } from "../utils/fetchNui";
import './App.css';

debugData([
  {
    action: "setVisible",
    data: true,
  },
]);

interface Job {
  job: string;
  label: string;
  grade: number;
  grade_label: string;
  removeable: boolean;
  active: boolean;
}

const App: React.FC = () => {
  const [isVisible, setIsVisible] = useState<boolean>(false);
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [closing, setClosing] = useState<boolean>(false);

  const showNotification = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    fetchNui('showNotification', { 
      message, 
      type 
    });
  };

  const fetchJobs = async () => {
    try {
      setLoading(true);
      const response = await fetchNui<{ success: boolean; jobs: Job[] }>('getJobs', {});
      
      if (response.success && response.jobs) {
        setJobs(response.jobs);
      } else {
        showNotification('Chyba při načítání prací', 'error');
      }
    } catch (error) {
      console.error('Error fetching jobs:', error);
      showNotification('Chyba připojení k serveru', 'error');
      
      setJobs([
        { job: 'police', label: 'Policie', grade: 3, grade_label: 'Kapitán', removeable: true, active: true },
        { job: 'ambulance', label: 'Záchranná služba', grade: 2, grade_label: 'Záchranář', removeable: true, active: false },
        { job: 'mechanic', label: 'Mechanik', grade: 1, grade_label: 'Začátečník', removeable: true, active: false }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const closeMenu = () => {
    setClosing(true);
    
    setTimeout(() => {
      setIsVisible(false);
      setClosing(false);
      fetchNui('hideUI', {});
    }, 300);
  };

  const handleSwitchJob = async (job: string, label: string) => {
    try {
      const response = await fetchNui<{ success: boolean; message: string }>('switchJob', { job });
      
      if (response.success) {
        setJobs(prev => prev.map(j => ({
          ...j,
          active: j.job === job
        })));
        showNotification(`Přepnuto na ${label}`, 'success');
      } else {
        showNotification(response.message || 'Nepodařilo se přepnout práci', 'error');
      }
    } catch (error) {
      console.error('Error switching job:', error);
      showNotification('Chyba připojení k serveru', 'error');
    }
  };

  const handleRemoveJob = async (job: string, label: string) => {
    try {
      const response = await fetchNui<{ success: boolean; message: string }>('removeJob', { job });
      
      if (response.success) {
        setJobs(prev => prev.filter(j => j.job !== job));
        showNotification(`Práce ${label} odebrána`, 'success');
      } else {
        showNotification(response.message || 'Nepodařilo se odebrat práci', 'error');
      }
    } catch (error) {
      console.error('Error removing job:', error);
      showNotification('Chyba připojení k serveru', 'error');
    }
  };

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      
      if (data.action === 'setVisible') {
        if (data.data) {
          setClosing(false);
          setIsVisible(true);
          fetchJobs();
        } else {
          closeMenu();
        }
      } else if (data.action === 'updateJobs') {
        if (data.jobs) {
          setJobs(data.jobs);
        }
      }
    };
    
    window.addEventListener('message', handleMessage);
    
    if (isVisible && !closing) {
      fetchJobs();
    }
    
    return () => {
      window.removeEventListener('message', handleMessage);
    };
  }, [isVisible, closing]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isVisible && !closing) {
        closeMenu();
      }
    };
    
    window.addEventListener('keydown', handleKeyDown);
    
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isVisible, closing]);

  if (!isVisible) return null;

  return (
    <div className={`multijob-container ${closing ? 'closing' : ''}`}>
      <div className={`multijob-panel ${closing ? 'panel-closing' : 'panel-opening'}`}>
        <div className="panel-header">
          <h2>Moje Práce</h2>
          <span className="job-count">{jobs.length}/3</span>
        </div>
        
        {loading ? (
          <div className="loading">Načítání prací...</div>
        ) : (
          <div className="jobs-list">
            {jobs.length === 0 ? (
              <div className="no-jobs">Žádné práce k dispozici</div>
            ) : (
              jobs.map((job) => (
                <div key={job.job} className={`job-item ${job.active ? 'active' : ''}`}>
                  <div className="job-info">
                    <div className="job-title">{job.label}</div>
                    <div className="job-grade">{job.grade_label}</div>
                    <div className="job-debug" style={{fontSize: '10px', color: 'gray'}}>
                      Removeable: {job.removeable ? 'Yes' : 'No'}, Active: {job.active ? 'Yes' : 'No'}
                    </div>
                  </div>
                  <div className="job-actions">
                    {!job.active && (
                      <button 
                        className="switch-btn"
                        onClick={() => handleSwitchJob(job.job, job.label)}
                      >
                        Přepnout
                      </button>
                    )}
                    {job.removeable && !job.active && (
                      <button 
                        className="remove-btn"
                        onClick={() => handleRemoveJob(job.job, job.label)}
                      >
                        Odebrat
                      </button>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default App;