package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformOutputs(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		//TerraformDir: "../path/to/terraform/config",
		TerraformDir: "../../../",
		Vars: map[string]interface{}{
			"region": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate Outputs
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID)

	albSecurityGroupID := terraform.Output(t, terraformOptions, "alb_sg_id")
	assert.NotEmpty(t, albSecurityGroupID)
	assert.True(t, aws.IsSecurityGroupExisting(t, albSecurityGroupID, awsRegion))

	appSecurityGroupID := terraform.Output(t, terraformOptions, "app_sg_id")
	assert.NotEmpty(t, appSecurityGroupID)
	assert.True(t, aws.IsSecurityGroupExisting(t, appSecurityGroupID, awsRegion))

	appAlbDNSName := terraform.Output(t, terraformOptions, "app_alb_dns_name")
	assert.NotEmpty(t, appAlbDNSName)

	appTargetGroupARN := terraform.Output(t, terraformOptions, "app_tg_arn")
	assert.NotEmpty(t, appTargetGroupARN)

	appListenerARN := terraform.Output(t, terraformOptions, "app_listener_arn")
	assert.NotEmpty(t, appListenerARN)

	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, s3BucketName)
	assert.True(t, aws.AssertS3BucketExists(t, awsRegion, s3BucketName))

	launchTemplateID := terraform.Output(t, terraformOptions, "launch_template_id")
	assert.NotEmpty(t, launchTemplateID)

	autoScalingGroupName := terraform.Output(t, terraformOptions, "autoscaling_group_name")
	assert.NotEmpty(t, autoScalingGroupName)

	s3PolicyARN := terraform.Output(t, terraformOptions, "s3_full_access_policy_arn")
	assert.NotEmpty(t, s3PolicyARN)

	iamUserName := terraform.Output(t, terraformOptions, "iam_user_name")
	assert.NotEmpty(t, iamUserName)

	s3BucketPolicyID := terraform.Output(t, terraformOptions, "s3_bucket_policy_id")
	assert.NotEmpty(t, s3BucketPolicyID)
}
