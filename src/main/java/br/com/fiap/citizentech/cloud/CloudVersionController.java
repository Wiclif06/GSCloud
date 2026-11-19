package br.com.fiap.citizentech.cloud;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.PropertySource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@PropertySource(value = "classpath:build-info.properties", ignoreResourceNotFound = true)
public class CloudVersionController {
    private final String commit;
    public CloudVersionController(@Value("${build.commit:local}") String commit) {
        this.commit = commit;
    }
    @GetMapping("/version")
    public Map<String, String> version() {
        return Map.of("application", "AgroConecta",
                "message", "AgroConecta: tecnologia a serviço do pequeno produtor.",
                "commit", commit);
    }
}
