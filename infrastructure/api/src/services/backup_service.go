package services

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

type BackupInfo struct {
	ID      string    `json:"id"`
	Name    string    `json:"name"`
	Size    int64     `json:"size"`
	ModTime time.Time `json:"modTime"`
}

type BackupService struct {
	dataPath    string
	backupPath  string
	logger      *logrus.Logger
	timeNowFunc func() time.Time
}

func NewBackupService(dataPath, backupPath string, logger *logrus.Logger) (*BackupService, error) {
	if err := os.MkdirAll(dataPath, 0o755); err != nil {
		return nil, fmt.Errorf("ensure data path: %w", err)
	}
	if err := os.MkdirAll(backupPath, 0o755); err != nil {
		return nil, fmt.Errorf("ensure backup path: %w", err)
	}
	return &BackupService{
		dataPath:    dataPath,
		backupPath:  backupPath,
		logger:      logger,
		timeNowFunc: time.Now,
	}, nil
}

func (s *BackupService) ListBackups() ([]BackupInfo, error) {
	entries, err := os.ReadDir(s.backupPath)
	if err != nil {
		return nil, err
	}
	var result []BackupInfo
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue
		}
		result = append(result, BackupInfo{
			ID:      e.Name(),
			Name:    e.Name(),
			Size:    info.Size(),
			ModTime: info.ModTime(),
		})
	}
	return result, nil
}

func (s *BackupService) CreateBackup() (BackupInfo, error) {
	ts := s.timeNowFunc().UTC().Format("20060102T150405Z")
	name := fmt.Sprintf("backup-%s.tar.gz", ts)
	dest := filepath.Join(s.backupPath, name)

	file, err := os.Create(dest)
	if err != nil {
		return BackupInfo{}, err
	}
	defer file.Close()

	gw := gzip.NewWriter(file)
	tw := tar.NewWriter(gw)

	err = filepath.Walk(s.dataPath, func(path string, info os.FileInfo, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		rel, err := filepath.Rel(s.dataPath, path)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}

		header, err := tar.FileInfoHeader(info, "")
		if err != nil {
			return err
		}
		// Normalize to forward slashes for tar
		header.Name = filepath.ToSlash(rel)

		if err := tw.WriteHeader(header); err != nil {
			return err
		}

		if info.Mode().IsRegular() {
			src, err := os.Open(path)
			if err != nil {
				return err
			}
			defer src.Close()
			if _, err := io.Copy(tw, src); err != nil {
				return err
			}
		}
		return nil
	})

	_ = tw.Close()
	_ = gw.Close()

	if err != nil {
		_ = os.Remove(dest)
		return BackupInfo{}, err
	}

	info, err := os.Stat(dest)
	if err != nil {
		return BackupInfo{}, err
	}

	return BackupInfo{
		ID:      name,
		Name:    name,
		Size:    info.Size(),
		ModTime: info.ModTime(),
	}, nil
}

func (s *BackupService) DeleteBackup(id string) error {
	target := filepath.Join(s.backupPath, filepath.Base(id))
	if !s.insideBackupPath(target) {
		return fmt.Errorf("invalid backup id")
	}
	return os.Remove(target)
}

func (s *BackupService) RestoreBackup(id string) error {
	target := filepath.Join(s.backupPath, filepath.Base(id))
	if !s.insideBackupPath(target) {
		return fmt.Errorf("invalid backup id")
	}

	if err := s.cleanDataPath(); err != nil {
		return err
	}

	file, err := os.Open(target)
	if err != nil {
		return err
	}
	defer file.Close()

	gr, err := gzip.NewReader(file)
	if err != nil {
		return err
	}
	defer gr.Close()

	tr := tar.NewReader(gr)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		destPath := filepath.Join(s.dataPath, filepath.FromSlash(hdr.Name))
		if !strings.HasPrefix(destPath, s.dataPath+string(os.PathSeparator)) && destPath != s.dataPath {
			return fmt.Errorf("path escapes data dir")
		}

		switch hdr.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(destPath, hdr.FileInfo().Mode()); err != nil {
				return err
			}
		case tar.TypeReg:
			if err := os.MkdirAll(filepath.Dir(destPath), 0o755); err != nil {
				return err
			}
			out, err := os.OpenFile(destPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, hdr.FileInfo().Mode())
			if err != nil {
				return err
			}
			if _, err := io.Copy(out, tr); err != nil {
				out.Close()
				return err
			}
			out.Close()
		}
	}

	return nil
}

func (s *BackupService) cleanDataPath() error {
	entries, err := os.ReadDir(s.dataPath)
	if err != nil {
		return err
	}
	for _, e := range entries {
		p := filepath.Join(s.dataPath, e.Name())
		if err := os.RemoveAll(p); err != nil {
			return err
		}
	}
	return nil
}

func (s *BackupService) insideBackupPath(path string) bool {
	abs, err := filepath.Abs(path)
	if err != nil {
		return false
	}
	backupAbs, err := filepath.Abs(s.backupPath)
	if err != nil {
		return false
	}
	return abs == backupAbs || strings.HasPrefix(abs, backupAbs+string(os.PathSeparator))
}
