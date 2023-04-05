import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.annotations.Test;

import java.time.Duration;

public class seleniumallure {

    @Test
    public void googlesearch() throws Exception {


        WebDriverManager.chromedriver().setup();
        WebDriver driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(15));


        driver.get("https://www.google.com");

        WebElement searchtext = driver.findElement(By.xpath("//input[@class='gLFyf']"));
        searchtext.sendKeys("mvnrepository");

        searchtext.submit();

        driver.quit();

    }


    @Test
    public void amazonsearch() {


        WebDriverManager.chromedriver().setup();
        WebDriver driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(15));

        driver.get("https://www.amazon.com");


        WebElement searchtext = driver.findElement(By.xpath("//input[@id='twotabsearchtextbox']"));
        searchtext.sendKeys("C++ code");

        searchtext.submit();


        driver.findElement(By.xpath("//span[@class='a-size-medium a-color-base a-text-normal']")).click();

        driver.quit();

    }
    @Test
    public void googlesearch2() throws Exception {


        WebDriverManager.chromedriver().setup();
        WebDriver driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(15));


        driver.get("https://www.google.com");

        WebElement searchtext = driver.findElement(By.xpath("//input[@class='gLFyf']"));
        searchtext.sendKeys("google");

        searchtext.submit();

        driver.quit();

    }


}