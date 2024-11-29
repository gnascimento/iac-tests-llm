package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformS3WithVpcEndpoint(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../",

		Vars: map[string]interface{}{
			"aws_region": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	websiteURL := terraform.Output(t, terraformOptions, "website_url")
	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	subnetID := terraform.Output(t, terraformOptions, "subnet_id")
	s3EndpointID := terraform.Output(t, terraformOptions, "s3_endpoint_id")

	aws.AssertS3BucketExists(t, awsRegion, bucketID)

	assert.True(t, aws.IsPublicSubnet(t, subnetID, awsRegion))

	s3BucketVersioning := aws.GetS3BucketVersioning(t, awsRegion, bucketID)
	assert.Equal(t, "Enabled", s3BucketVersioning)

	s3BucketLoggingTarget := aws.GetS3BucketLoggingTarget(t, awsRegion, bucketID)
	assert.Equal(t, bucketID+"-logs", s3BucketLoggingTarget)

	s3BucketLoggingTargetPrefix := aws.GetS3BucketLoggingTargetPrefix(t, awsRegion, bucketID)
	assert.Equal(t, "TFStateLogs/", s3BucketLoggingTargetPrefix)

	tags := aws.GetTagsForVpc(t, vpcID, awsRegion)
	assert.Equal(t, "tag-value", tags["tag-key"])

	vpcs := aws.GetVpcsE(t, []*ec2.Filter{}, awsRegion)
	assert.Equal(t, vpcID, vpcs[0].Id)

	subnets := aws.GetSubnetsForVpc(t, vpcID, awsRegion)
	assert.Equal(t, subnetID, subnets[0].Id)

	s3Endpoint := aws.GetVpcEndpointByIdE(t, s3EndpointID, awsRegion)
	assert.Equal(t, s3EndpointID, s3Endpoint.ID)
}
