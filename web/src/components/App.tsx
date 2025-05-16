import React, { useState, useEffect } from 'react';
import { debugData } from "../utils/debugData";
import { fetchNui } from "../utils/fetchNui";
import { isEnvBrowser } from "../utils/misc";
import './App.css';
import { CURRENT_LANG } from '../config/lang';
import { t } from '../config/languages';

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
  removable: boolean;
  active: boolean;
}

const App: React.FC = () => {
  const [isVisible, setIsVisible] = useState<boolean>(false);
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [closing, setClosing] = useState<boolean>(false);

  const showNotification = (message: string, type: 'success' | 'error' | 'info' = 'info', vars?: Record<string, string|number>) => {
    fetchNui('showNotification', { 
      message: t(CURRENT_LANG, message, vars),
      type 
    });
  };  const fetchJobs = async () => {
    try {
      setLoading(true);
      console.log('[App] Fetching jobs...');
      
      // Provide dummy jobs in development/browser mode
      if (import.meta.env.MODE === "development" && isEnvBrowser()) {
        console.log('[App] Using browser mock data for jobs');
        const mockJobs = [
          { job: 'police', label: 'Police', grade: 3, grade_label: 'Captain', removable: true, active: true },
          { job: 'ambulance', label: 'Ambulance', grade: 2, grade_label: 'Paramedic', removable: true, active: false },
          { job: 'mechanic', label: 'Mechanic', grade: 1, grade_label: 'Novice', removable: true, active: false }
        ];
        console.log('[App] Mock jobs:', mockJobs);
        setJobs(mockJobs);
        setLoading(false);
        return;
      }
      
      const response = await fetchNui<{ success: boolean; jobs: Job[] }>('getJobs', {});
      console.log('[App] Jobs response:', response);
      
      if (response.success && response.jobs) {
        console.log('[App] Received jobs:', response.jobs);
        console.log('[App] Jobs with removable flag:', response.jobs.filter(job => job.removable));
        setJobs(response.jobs);
      } else {
        console.error('[App] Error fetching jobs:', response);
        showNotification('notification_fetch_error', 'error');
      }
    } catch (error) {
      console.error('Error fetching jobs:', error);
      showNotification('Chyba připojení k serveru', 'error');
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
        showNotification('notification_job_switched', 'success', { label });
      } else {
        showNotification('notification_error', 'error');
      }
    } catch (error) {
      console.error('Error switching job:', error);
      showNotification('Chyba připojení k serveru', 'error');
    }
  };
  const handleRemoveJob = async (job: string, label: string) => {
    try {
      console.log(`[App] Attempting to remove job: ${job} (${label})`);
      const response = await fetchNui<{ success: boolean; message: string }>('removeJob', { job });
      
      console.log(`[App] Remove job response:`, response);
      
      if (response.success) {
        setJobs(prev => prev.filter(j => j.job !== job));
        showNotification('notification_job_removed', 'success', { label });
      } else {
        console.error(`[App] Failed to remove job: ${response.message}`);
        showNotification('notification_error', 'error');
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
      if ((e.code === 'Escape' || e.code === 'Backspace') && isVisible && !closing) {
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
          <h2>{t(CURRENT_LANG, 'jobs_title')}</h2>
          <span className="job-count">{t(CURRENT_LANG, 'job_count', { count: jobs.length })}</span>
        </div>
        
        {loading ? (
          <div className="loading">{t(CURRENT_LANG, 'loading')}</div>
        ) : (
          <div className="jobs-list">
            {jobs.length === 0 ? (
              <div className="no-jobs">{t(CURRENT_LANG, 'no_jobs')}</div>
            ) : (
              jobs.map((job) => (
                <div key={job.job} className={`job-item ${job.active ? 'active' : ''}`}>
                  <div className="job-info">
                    <div className="job-title">{job.label}</div>
                    <div className="job-grade">{job.grade_label}</div>
                  </div>                 
                   <div className="job-actions">
                    {job.active ? ( job.removable && job.job !== 'unemployed' ? (
                        <button 
                          className="remove-btn"
                          onClick={() => handleRemoveJob(job.job, job.label)}
                        >
                          {t(CURRENT_LANG, 'remove')}
                        </button>
                      ) : null
                    ) : (
                      <button 
                        className="switch-btn"
                        onClick={() => handleSwitchJob(job.job, job.label)}
                      >
                        {t(CURRENT_LANG, 'switch')}
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