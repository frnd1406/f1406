package services

import (
	"errors"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

var ErrPathTraversal = errors.New("path escapes base directory")

// StorageEntry represents a file or directory item within the storage root.
type StorageEntry struct {
	Name    string    `json:"name"`
	Size    int64     `json:"size"`
	IsDir   bool      `json:"isDir"`
	ModTime time.Time `json:"modTime"`
}

// StorageService provides basic file operations within a confined base directory.
type StorageService struct {
	basePath string
	logger   *logrus.Logger
}

// NewStorageService initializes the service and ensures the base path exists.
func NewStorageService(basePath string, logger *logrus.Logger) (*StorageService, error) {
	if basePath == "" {
		return nil, fmt.Errorf("base path is required")
	}

	absBase, err := filepath.Abs(basePath)
	if err != nil {
		return nil, fmt.Errorf("resolve base path: %w", err)
	}

	if err := os.MkdirAll(absBase, 0o755); err != nil {
		return nil, fmt.Errorf("ensure base path: %w", err)
	}

	return &StorageService{
		basePath: absBase,
		logger:   logger,
	}, nil
}

func (s *StorageService) sanitizePath(rel string) (string, error) {
	if strings.Contains(rel, "..") {
		return "", ErrPathTraversal
	}
	// Prepend slash so Clean treats it as absolute, then trim to avoid breaking out.
	cleaned := filepath.Clean("/" + rel)
	trimmed := strings.TrimPrefix(cleaned, "/")
	full := filepath.Join(s.basePath, trimmed)

	abs, err := filepath.Abs(full)
	if err != nil {
		return "", err
	}

	if abs != s.basePath && !strings.HasPrefix(abs, s.basePath+string(os.PathSeparator)) {
		return "", ErrPathTraversal
	}

	return abs, nil
}

// List returns the entries for the given relative path.
func (s *StorageService) List(relPath string) ([]StorageEntry, error) {
	target, err := s.sanitizePath(relPath)
	if err != nil {
		return nil, err
	}

	entries, err := os.ReadDir(target)
	if err != nil {
		return nil, err
	}

	var items []StorageEntry
	for _, e := range entries {
		info, err := e.Info()
		if err != nil {
			s.logger.WithError(err).Warn("storage: failed to read entry info")
			continue
		}

		items = append(items, StorageEntry{
			Name:    e.Name(),
			Size:    info.Size(),
			IsDir:   info.IsDir(),
			ModTime: info.ModTime(),
		})
	}

	return items, nil
}

// Save stores the provided file into the given relative directory.
func (s *StorageService) Save(dir string, file multipart.File, filename string) error {
	if filename == "" {
		return fmt.Errorf("filename is required")
	}

	targetDir, err := s.sanitizePath(dir)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return fmt.Errorf("create target dir: %w", err)
	}

	destPath, err := s.sanitizePath(filepath.Join(dir, filepath.Base(filename)))
	if err != nil {
		return err
	}

	dest, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer dest.Close()

	if _, err := io.Copy(dest, file); err != nil {
		return fmt.Errorf("write file: %w", err)
	}

	return nil
}

// Open returns a file handle and metadata for download.
func (s *StorageService) Open(relPath string) (*os.File, os.FileInfo, string, error) {
	target, err := s.sanitizePath(relPath)
	if err != nil {
		return nil, nil, "", err
	}

	info, err := os.Stat(target)
	if err != nil {
		return nil, nil, "", err
	}
	if info.IsDir() {
		return nil, nil, "", fmt.Errorf("cannot download a directory")
	}

	f, err := os.Open(target)
	if err != nil {
		return nil, nil, "", err
	}

	ctype := mime.TypeByExtension(filepath.Ext(info.Name()))
	if ctype == "" {
		buf := make([]byte, 512)
		n, _ := f.Read(buf)
		ctype = http.DetectContentType(buf[:n])
		if _, err := f.Seek(0, io.SeekStart); err != nil {
			f.Close()
			return nil, nil, "", err
		}
	}

	return f, info, ctype, nil
}

// Delete removes a file or directory (recursively) within the storage root.
func (s *StorageService) Delete(relPath string) error {
	if relPath == "" || relPath == "/" || relPath == "." {
		return fmt.Errorf("refusing to delete storage root")
	}

	target, err := s.sanitizePath(relPath)
	if err != nil {
		return err
	}

	return os.RemoveAll(target)
}
