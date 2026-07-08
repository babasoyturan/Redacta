package oopsops.app.document.service;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@ConditionalOnProperty(
        name = "storage.type",
        havingValue = "s3"
)
public class S3StorageService implements StorageService {

    @Override
    public String store(MultipartFile file) {
        // TBD
        // Placeholder for S3 storage logic
        return null;
    }

}
